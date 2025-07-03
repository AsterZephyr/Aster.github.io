---
title: "kafka日常实践 操作"
date: 2025-07-02T14:25:26Z
draft: false
tags: ["分布式系统", "系统架构", "数据库", "存储", "性能优化", "高并发"]
author: "Aster"
description: "Created: 2025年3月5日 11:20..."
---

# kafka日常实践 操作

Created: 2025年3月5日 11:20
Status: 完成

# **一、使用场景&技术选型&快速使用：**

### **1、MQ的使用场景**

MQ（Message Queue），消息队列，顾名思义，一个系统发消息到队列里，另一个系统从队列里拿出消息。所以MQ一般会应用在两个系统进行异步通讯传递消息。在遇到高并发、服务交互、异步调用等常见场景时，利用消息中间件的**削峰、填谷、解耦**等特性可以快速实现这些复杂场景，从而实现业务解耦、提升代码的易维护性、提高系统稳定性。以下场景中，我们通常可看到MQ的使用。

- 业务解耦：比如下单之后发送短信、邮件、站内信等通知，数据离线同步等。
- 日志收集：微服务场景下收集大量日志数据，系统的操作记录收集等
- 高并发场景：比如秒杀场景，大量请求压过来，如果所有流程都放在同一个服务处理，估计服务cpu都会打满。此时利用MQ的削峰填谷特性，上层系统只承担部分任务，然后把请求丢到消息队列中让后续系统完成处理，从而快速释放请求压力。

### **2、技术选型**

目前消息中间件领域主要的中间件包括 RocketMQ、Kafka 和 RabbitMQ，我们先来看一下这张功能对比图：

我手的技术栈主要是Java，因此我们平时主要是在Kafka和RocketMQ之间做选型。

这里要特殊说明事务消息这个点。RocketMQ解决的是本地事务的执行和发消息这两个动作满足事务一致性，而Kafka的事务消息是指在一个事务中发送的多条消息要么一起成功要么一起失败。

因此从事务消息、消息重试这几个点出发的话， RocketMQ 很适合核心业务场景，而Kafka更加擅长于日志、大数据计算等场景。

### **3、快速使用**

在我手，使用Kafka时的使用步骤就是：青藤上创建topic，生产者生产消息发送到topic，消费者拉取消息进行消费。本篇文章主要想讨论kafka在使用上的一些常见问题，使用步骤就不赘述了，具体见：[https://halo.corp.kuaishou.com/help/docs/2dfd922345345e0354d4f576c753934c](https://halo.corp.kuaishou.com/help/docs/2dfd922345345e0354d4f576c753934c)

# **二、kafka快速入门**

接下来，让我们快速了解一下kafka的基本结构。

### **1、kafka基本架构**

Kafka 的设计遵循生产者消费者模式，生产者Producer发送消息到 broker 中某一个 topic 的具体分区里，消费者Consumer从一个或多个分区中拉取数据进行消费。

### **2、Kafka术语介绍**

- **Broker**：Kafka的服务器端由被称为Broker的服务进程构成，即一个Kafka集群由多个Broker组成。Broker负责接收和处理客户端发送过来的请求，以及对消息进行持久化。多个 broker 组成一个 Kafka 集群，通常一台机器部署一个 Kafka 实例，一个实例挂了不影响其他实例。
- **Kafka客户端**：生产者Producer和消费者Consumer，Producer发消息到broker中某一个 topic 的具体分区里，消费者Consumer从一个或多个分区中拉取数据进行消费。
- **消息**：Record。Kafka是消息引擎，这里的消息就是指Kafka处理的主要对象。
- **主题**：Topic。主题是存储消息的逻辑单元，在实际使用中用来区分具体的业务。
- **分区**：Partition。一个有序的消息序列。分区在机器磁盘上以日志文件出现，采用顺序追加日志的方式添加新消息、实现高吞吐量。
- **消息位移**：Offset。表示分区中每条消息的位置信息，是一个单调递增且不变的值。
- **副本**：Replica。Kafka中同一条消息能够被拷贝到多个地方以提供数据冗余，这些地方就是所谓的副本。副本还分为领导者副本（leader副本）和追随者副本（follower副本），各自有不同的角色划分。副本是在分区层级下的，即每个分区可配置多个副本实现高可用。
- **消费者位移**：Consumer Offset。表征消费者消费进度，每个消费者都有自己的消费者位移。
- **消费者组**：Consumer Group。多个消费者实例共同组成的一个组，同时消费多个分区以实现高吞吐。
- **重平衡**：Rebalance。Rebalance是让一个Consumer Group下所有的Consumer实例就如何消费订阅主题的所有分区达成共识的过程。当消费者组内消费者实例发生变化时（加入或离开），其余消费者实例会自动重新分配订阅主题分区。

**主题、消息、分区、位移、副本、生产者、消费者的关系：**

一个Topic会有m个分区，每个分区会有n个副本（1个leader副本和n-1个follower副本），生产者和消费者只会向leader副本生产和消费。一个分区内会有若干条消息，例如如果分了10个分区，不同的消息放在10个分区里，可以将消息发送到特定的分区内实现有序。每个分区的消息位移从0开始。

# **三、日常开发使用的一些常见问题**

开发过程中会遇到的常见问题有：kafka如何保证消息不会丢失？kafka生产重试和消费重试怎么做？如何保证消息有序生产&有序消费？kafka是否能精确地做到一次生产一次消费？

诸如此类的问题很琐碎，但其实在我们日常开发时，最后只会落到申请MQ、开发生产者、开发消费者这三个步骤有关。下面我们从一个真实的场景来开发mq，走一遍完整的开发kafka的流程。

结合实事，最近元中心B1入驻很多新的餐饮商户，一到饭点人流量巨大，有的餐厅下单完等饭等好久，想象一下这中间发生了什么？设想这样一个需求，当我们用手机扫码点餐时，下单完成；后台厨师餐饮系统收到下单消息，开始备餐；用户吃完前台结账支付订单，至此完成订单。

如果直接用接口访问后台厨师的餐饮系统，高并发的请求对系统是个不小的挑战，因此我们打算使用MQ解耦订单系统和厨师后台系统。下面我们来一起来设计这个流程。

### **1、申请MQ需要注意哪些**

首先我们要做的就是申请一个kafka topic，申请一个topic。运维类操作这里不赘述，我们最关心的是以下几个问题：

- **为了保证高可用性，我们应该设置几个副本？**

一般我们新建的topic默认都是2个副本，不过这样，只要一个副本挂了，那另一个就无法保证高可用了。所以如果你的服务特别重要，建议设置>=3个副本。

- **如何根据TPS来设置几个分区？**

假设我们的一条消息为1kB，一家店在1秒预估多一点有100桌来吃饭，那么最多也就是生产者的消息写入qps最高为：100条/s；如果后续我们这个系统接入了1000家店，那么写入qps最高100k/s。假设一条消息为100B, 那么写流量最多为100B * 100k/s = 10MB/s, 如果每个分区最多支持5MB/s的写入，那么我们至少需要2个分区。之后我们再按消费者的实际消费能力设置消费者及其线程数。

- **topic的分区数可以增加或减少吗？**

线上变更topic分区会出现rebalance，影响服务，所以通常是不建议变更分区数。（为啥rebalanc会影响服务，我们会在之后说到）

- **总结**

（1）想保证高可用，设置副本个数：replication.factor >= 3

（2）根据你的tps设置分区

（3）尽量不要更改topic分区数

### **2、开发生产者需要注意哪些**

这一步我们要开发一个生产者，当客人下单，生产者发一条消息到后台餐饮系统。这一步就是Producer向broker发一条消息，这条代码很简单，但在运行中很快就出现了问题。

```java
//...客户已下单，发一条消息
KafkaProducers.sendString("cook_topic", "order_message");
```

- **如何保证消息一定会发出去？**

我们收到了一条投诉，客人下单了，但是厨师的后台系统却没收到这条消息。这引来我们的第一个问题，这条消息是丢了吗？Kafka把一条已发送的消息弄丢了吗？

**问题1：消息丢失了吗？**

生产者发到Kafka的消息会不会丢失呢？官方做了这样的保证：

📌

Kafka只对**“已提交”的消息**（committed message）做**有限度的持久化**保证。

这里有两个关键词：

**一是“已提交”的消息**：

当kafka的若干个broker确认接收到消息并保存到日志文件里，返回给生产者成功提交的信息，这样的消息就是**“已提交”的消息。**

至于这里的若干个broker，你既可以指定1台broker，也可以指定所有broker。不过要确保消息不会在一台broker宕机时就丢失，通常会建议指定所有broker都确认收到才算作已提交。**这里的生产者配置参数为：acks = all**

**二是有限度的持久化：**

kafka不能保证任何情况下都能将消息持久化保存，也就是说，broker里至少有一个是存活的才能保证消息被持久化。如果broker都挂了，那也没办法接收到消息了。

所以通常我们讨论的无消息丢失，必须基于以上kafka的保证为前提。

**问题2：如何保证生产者不会丢失数据呢 ？**

如果生产者在每次发消息时，发完就不管返回结果了（fire and forget），那么这条消息到底有没有发到broker上就得不到保证了。所以，如果想保证生产者一定能将消息发到broker，那么就一定要关心消息发送后的结果，保证每条消息一定会发送成功。

所以如何得到消息发送后的结果呢？这里我们不要使用producer.send(msg)，要用**producer.send(msg, callback)**，用**回调方法**去判断生产者是否成功发送消息到broker。如果没有发送成功，那么必要时可采用**定时任务兜底**来保证消息一定能成功发送。

有回调结果的发消息示例：

```java
//生产者发送消息
public void sendMessage(MessageProto message) {
        ListenableFuture<RecordMetadata> listenableFuture =
                KafkaProducers.sendProto(your_topic_name, message);
        Futures.addCallback(listenableFuture, buildFutureCallback(this::sendFail, message),
                RETRY_SEND_MSG_THREAD_POOL);

    }

/**
     * Kafka异步发送，发送数据后处理发送结果
     */
    private FutureCallback<RecordMetadata> buildFutureCallback(
            BiConsumer<Throwable, MessageProto> failure,
            MessageProto message) {
        FutureCallback<RecordMetadata> futureCallback = new FutureCallback<RecordMetadata>() {
            @Override
            public void onSuccess(@Nullable RecordMetadata recordMetadata) {

                LOGGER.info("[sendMessage] send mq success, message = {}",
                        ObjectMapperUtils.toJSON(message));
            }

            @Override
            public void onFailure(Throwable throwable) {
                if (failure != null) {
                    failure.accept(throwable, message);
                }
            }
        };
        return futureCallback;
    }
/**
     * 处理消息发送失败的结果
     */
    private void sendFail(Throwable throwable, MessageProto message) {

        LOGGER.error("[sendMessage]fail to  send mq, message = [{}]",
                ObjectMapperUtils.toJSON(message), throwable);
    }
```

- **如何保证消息按序发送？**

接着，又过了一会，我们收到了第二条投诉。有客人抱怨自己明明比隔壁桌早下单，结果比隔壁桌上菜晚？厨师表示，他都是按照消息来的顺序做菜的，绝不可能做错顺序。这时我们返回排查系统，发现厨师那边的后台系统确实乱序消费了信息。

看了看系统架构，我们发现，producer在发消息时是随机发送到topic的分区的，那这样consumer在拉取时，就不一定会先消费哪个消息了。

因此，我们需要将生产者改为有序发送，同一家商户的下单消息必须发送到同一个分区里，这样consumer在消费时从每个partition里拉出的消息一定是有序的了。

- **总结**

（1）配置Producer端参数 acks=all，保证消息一定发送到所有broker

（2）使用带回调结果的发送方法，必要时可用定时任务兜底，确保生产者成功发送消息。

（3）判断消息是否有序，如果有顺序，那么按照一定的顺序指定发到对应的分区。

### **3、开发消费者需要注意哪些**

这一步我们要开发一个消费者，当客人下单，生产者发一条消息到后台餐饮系统后，消费者收到消息，将数据写入厨师的后台系统，来一起看一看我们会遇到什么问题。

```java
public class OrderMessageConsumer implements KsKafkaConsumer<String> {
    private static final Logger logger = LoggerFactory.getLogger(OrderMessageConsumer.class);

    @Override
    public void consume(String message, MessageContext context) {
        logger.info("receive order message: {}", message);
        //写入厨师系统

    }

    @Override
    public String topic() {
        return "cook_topic";
    }

    @Override
    public String consumerGroup() {
        // 消费者组，不同的consumer尽量使用不同的group!
        // 原因后面rebalance节讲
        return "orderMessageConsumerGroup";
    }

}
```

- **如何保证消息一定会被消费到？**

等等，我们上一节开发生产者的时候已经保证producer一定发消息到broker了，为啥这里消息又丢失了呢？

在Kafka中默认的消费位移的提交方式是自动提交，这个由消费者客户端参数 enable.auto.commit 配置，默认值为true。当然这个默认的自动提交不是每消费一条消息就提交一次，而是定期提交，这个定期的周期时间由客户端参数auto.commit.interval.ms配置，默认值为5秒（此参数生效的前提是enable.auto.commit参数为rue）。这里常见情况是，自动提交里消息如果已经被消费但未提交位移，就会出现重复消费的情况。那什么情况下消息会丢失呢？

**问题1：消息为什么会丢失？**

消息都是从broker端拉下来的，消费者怎么会丢消息呢？

我们看下面这张图。对于Consumer A而言，它当前消费到的消息位移值就是9；Consumer B的位移值是11。这里的“位移”类似于我们看书时使用的书签，它会标记我们当前阅读了多少页，下次翻书的时候我们能直接跳到书签页继续阅读。

假设消费者一次从broker端拉取10条消息，正确更新位移“书签”的步骤是先处理这10条消息，再更新位移。但如果没有处理完这批消息就更新了位移呢？

设想这样一个场景：consumerB从位移11这里开始拉取了11-20这10条消息，拉取消息完成后，就将位移更新到21。这时B再去处理11-20这10条消息。在处理到15这条消息时，突然发生了服务异常中断的情况，那么问题就来了，消费者再次重新启动时，是去broker端从位移21拉取消息，这样消费者就弄丢了16-20这5条消息，也就是说16-20这5条消息就丢失了。

所以为了避免这样的情况，办法也很简单：**保证先消费消息，再更新位移的顺序**即可。这样就能最大限度地保证消息不丢失。

还有一种比较隐蔽的case是，如果Consumer有多个处理消息的worker线程，consumer本身默认是自动地不断向前更新位移。这时其中的一个worker线程运行失败了，它负责处理的消息还没被成功处理，但这条消息的位移已经被自动提交更新了。此时这条消息就相当于丢失了。

对应的解决办法是，**关掉自动提交位移，改成手动提交**，在确定处理成功后再手动提交位移。但是管理位移实在太复杂，所以在生产环境中，我还没有见过手动提交位移的写法。就不在文中对此深入展开了。

**问题2：消息没有丢失，但是消费时没有将订单成功写入厨师后台**

这里消费失败了我们没有做任何重试，没写入后台，从厨师角度看起来好像就像消息丢了一样。

那么如何做消费者的失败重试呢？

我手提供的kafka client提供了两种重试机制，本地重试和远程重试，配置分别是：

```java
//本地重试策略
public RetryStrategy<String> retryStrategy() {
        return LocalRetryStrategyBuilder.newBuilder()
                .addRetryException(RuntimeException.class)  //支持重试的异常，默认 Exception.class
                .backoffFactory(retryTime-> Duration.ofSeconds(5)) //重试避让时间，默认：0秒
                .maxRetryCount(2) //最大重试次数，默认：1
                .build();
}
//远程重试策略：
public RetryStrategy<String> retryStrategy() {
           return RemoteRetryStrategyBuilder.newBuilder()
                    .retryTopicName("retry_topic_name") //重试TopicName。若未配置，默认使用 "TopicName__ConsumerGroup__retry"
                    .retryReportName("retry_report_name") //重试ReportName,会在框架监控中展示。若未配置，默认使用"ReportName__ConsumerGroup__retry"
                    .retryConsumerGroup("retry_Consumer_group") //重试ConsumerGroup。若未配置，默认使用 "ConsumerGroup__retry"
                    .useDeadLetterQueue(true) //重试失败后,是否发送到死信topic
                    .dlqTopicName("dlq_topic_name") //死信TopicName。 若未配置，默认使用"TopicName__ConsumerGroup__dlq"
                    .maxRetryCount(3) //消费异常最大重试次数。默认重试1次
                    .delayTime(Duration.ZERO) //重试延迟时间(目前基于kafka延迟消费能力实现，broker端时间索引构建机制优化前，暂不建议设置）
                    .addRetryException(Exception.class) //支持重试的异常类型
                    .strict(false) //是否需要严格保证重试、死信topic发送成功，默认:false,且强烈建议false。
                    .build();
 }
```

本地重试和远程重试的流程对比图如下，可以看到本地重试就是在消费者内部重试消费消息直到成功后提交位移，远程重试就是将出错的消息放到专门放重试消息的topic中，由其他consumer服务进行处理。那么这两种模式应该怎样选择呢？下面我们来分析其利弊。

本地重试和远程重试最显著的差别就是同步和异步处理消息。

对于本地重试来说，能够同步地处理消息，优势在于：不会改变消息的消费顺序，在处理有序消息时非常有用。但缺点也很明显，如果设置了不合理的重试次数，或者一批消息都进行重试时，那么会导致消费者这批消息处理时间过长，迟迟无法提交位移拉取下一部分消息，当consumer两次拉取消息的时间超过max.poll.interval.time配置，（目前我手默认配置是5分钟），那么consumer就会自动退出消费者组，从而导致rebalance（rebalance问题具体见下节）。如这篇kstack[探究kafka重试引起的Rebalance风暴](https://kstack.corp.kuaishou.com/article/9006)，就是一个典型的本地重试引起的大量rebalance情形。

那么远程重试就毫无缺点吗？看起来远程重试的流程无懈可击，但它最大的问题是：**异步重试消息会忽略消息顺序**。如果消息需要被有序消费，那么远程重试是无法做到有序的。如果这时采用了远程重试策略，那么乱序错误还会被隐藏，可能会攒出更大的错误才会被发现。

远程重试的优点不赘述了，此处再提一个容易被忽略的注意事项，在实现远程重试之前，我们应 100％确定：**业务中不会有消费者更新消息。**

总结下，本地重试和远程重试适用的情形如下：

|  | 本地重试 | 远程重试 |
| --- | --- | --- |
| 特点 | 消费者内部处理
同步处理消息 | 消费者外部处理
异步处理消息 |
| 优点 | 不改变消息的消费顺序 | 消费者的健壮性更好，不易引起rebalance |
| 缺点 | 重试时间过长时，易引发rebalance | 不保证消息按序消费 |
| 适用情形 | 针对短时可恢复的错误，可使用本地重试 | 针对可乱序消费的消息、以及出现不可恢复的错误时，可使用远程重试 |

在实际生产时，可以**本地重试+远程重试**一起使用，对于短期可恢复的错误类型，使用本地重试快速解决；对于短期不可恢复的错误，放到重试topic里；对于者重试好多次依然失败的错误，直接送到死信topic里，使用**定时任务轮询兜底**处理死信消息。

- **消息能保证按序消费吗**

在上节开发生产者里，我们已经让生产者按序生产了，按理说，对于同一家商户，消费者已经消费的是有序的消息了，为啥还会乱序呢？

这里我们来看下这几个消费者注意事项：

- 不能设置--worker-threads>1
- 不能使用异步重试策略
- 遇到服务重启、扩容缩容等上下线操作，或发生rebalance过程时，无法保证强顺序消费。（消息无法避免重复消费）

可见kafka是无法一定保证消息的强顺序的。

- **一条消息能保证只消费一次吗？**

有个商户地来反馈了，客人买了一份菜，给他上了两份菜，厨师收到了两个订单，多做了一份。

通过检查消费者逻辑发现，我们的消费者在收到重复订单消息后，没有做幂等处理，导致写入了两份订单。

从生产者发出这条消息开始，生产者每发一条消息就会等待一次broker的response，如果这条response因为各种原因没有返回到生产者，那么上游生产者就会重发消息，这样就可能发多次这样的重复消息，也就无法提供确保只订单消息生产一次的能力。

同理consumer在处理完一条消息后，因为各种原因位移没有提交到broker，那么下次consumer再拉取消息消费时，就会出现重复消费。

对于kafka来说，消息无丢失是很好保证的。但是非常容易会有重复消费的情况，所以一定要做好消息幂等的处理。对于这个问题，我们根据订单号唯一性，做好消息的消费幂等处理，保证一条消息只会产生唯一一个的订单。

- **总结**

（1）保证消息不丢失的话，需要设置消费者先消费消息，再提交位移；

（2）想要保证消费成功才能提交位移，就设置为手动提交位移；默认是自动提交位移

（3）消费者端无法保证100%按序处理

（4）消费重试方案要根据业务实际诉求来设计

（5）做好消费者的幂等处理

### **4、开发中怎么用kafka的泳道？**

### **kafka消息里怎么标识泳道？**

如果一个服务线程的traceContext里带了泳道标识，那么生产的kafka消息也会带泳道标识。泳道信息会放在消息的key中，业务自定义的消息会放在消息value中。

kafka消息类型：

我手kafka消息的key里塞了啥：

### **生产者怎么生产带泳道id的消息？**

生产者发送消息时，如果线程上下文中的TraceContext信息有泳道标识lane.A，就会发送带有泳道lane.A的消息，而这与生产者所部署的环境并不相关。

如果想单独只生产一条泳道环境的消息，staging环境可以使用kdev平台的mock消息发送：

[https://kdev.corp.kuaishou.com/web/mock-mgr/messageplatform/topiclist](https://kdev.corp.kuaishou.com/web/mock-mgr/messageplatform/topiclist)

### **消费者是怎么消费泳道消息的？**

我们部署consumer的泳道服务，就可以使用泳道环境了。

1、consumer部署在泳道后，消费者将自己的消费者组名-泳道名字作为新的消费者组名注册到青藤上。

2、消费者拉取下来Topic的全量消息之后，会把消息中的泳道标识等上下文信息，重新注入到线程上下文中，然后根据不同环境的泳道过滤留下当前泳道的消息，在消费逻辑要调用下游服务时，会将上下文再传递给下游服务。

### **总结**

下面是在三个环境下，消费者的默认消费规则及说明：

[无标题](kafka%E6%97%A5%E5%B8%B8%E5%AE%9E%E8%B7%B5%20%E6%93%8D%E4%BD%9C%201ad4bf1cd99880c59fcbe037f3fa67b0/%E6%97%A0%E6%A0%87%E9%A2%98%201ad4bf1cd9988026a815ea8280e98418.csv)

### **5、Kafka的PRT环境使用注意事项**

上述kafka的泳道方案在staging环境基本没有缺点，但是在线上和prt环境有几个问题。

（1）prt环境会收到线上的全量消息。

（2）prt环境的泳道仅支持完全匹配，不支持泳道的级联、并列、回落。

（3）线上默认是可以消费prt消息的。

那么如何才能将prt环境和线上完全隔离开呢？

### **怎么使用PRT环境隔离方案？**

这里，kafka还提供了一种prt环境隔离的方案。[Kafka PRT环境隔离使用文档](https://docs.corp.kuaishou.com/d/home/fcADJto2WQBx8idywOP-0di_K)

这里我们不赘述流程，只简述原理。

方案中，我们创建一个topic_prt来物理隔离线上和prt环境的消息。然后开启consumer能消费topic_prt信息。从下图中可以看到，隔离后，prt环境的consumer就只消费topic_prt了，不会再消费正式消息了。

这里我们来看下这几个问题。

（1）topic_prt的消息还会回落到线上吗？

我们在创建topic_prt后，如果没有创建prt环境的消费者组或者没有配置可隔离消费，那么topic_prt的消息会回落到线上消费。

这里为了避免topic_prt和topic同时使用一个消费者组可能造成rebalance相互影响，以及topic_prt如果出现线上消费和prt消费的重复消费和漏消费问题，消费者组会自动追加”-lane-PRT“的后缀。

在代码中可以看出，默认是会回落到线上消费。如果不需要回落，需要在kstable平台关闭回落。

（2）PRT环境里支持泳道的级联&并列&回落。

PRT环境下的主干就是PRT，只要部署了consumer的PRT主干环境，那么PRT环境的消息都会经过PRT主干。如果没有配置特定PRT泳道，主干PRT会消费消息。

（3）实际case分享

在实际使用中，还遇到过一种因prt泳道而导致消息丢失的特殊情况。

如果消息的生产者未开启隔离配置，消费者开启隔离配置；又已知线上的consumer加了不消费PRT泳道消息的配置。这时会出现什么情况呢？

当PRT环境的生产者再发出带PRT泳道的消息到这个topic时，我们知道线上consumer不消费这个prt泳道消息；同时PRT环境的消费者因为已经配置了隔离，只会消费topic_prt的消息，也不会消费到这条消息，因此这条消息相当于就失踪了。

### **总结**

|  | PRT环境 | 线上环境 |
| --- | --- | --- |
| 配置了支持隔离的生产者 | PRT泳道的流量将会发送到PRT的topic（带有"_prt"后缀的topic） | 正式流量还是发送到线上的Topic |
| 配置了支持隔离的消费者 | 1. 只消费PRT的topic（带有"_prt"后缀的topic）
2. 使用自己的泳道进行过滤；
3. 支持泳道的及联、并列；
4. 未部署对应泳道的消息将回落PRT主干消费 | 只消费线上的Topic |
| 没配置支持隔离的消费者（还是普通的消费者） | 不进行消费 | 消费PRT的Topic和线上的Topic |

# **四、日常oncall维护的一些常见问题**

日常oncall维护中会我们遇到的常见问题有：如何应对rebalance？如何应对消费lag？

### **1、为什么对rebalance如临大敌？如何避免？遇到了要怎么处理？**

Rebalance是指在一个Consumer Group里，当前所有的Consumer实例就如何消费订阅主题的所有分区达成共识的过程。当Consumer Group内Consumer实例发生变化时（加入或离开），其余消费者实例会自动重新分配订阅主题分区。

为什么一般服务遇到这个过程时我们都如临大敌呢？因为Rebalance过程非常影响我们的服务可用性。原因为以下3个：

- Rebalance影响Consumer端TPS。在Rebalance期间，所有Consumer实例都不能消费任何消息，什么也干不了。
- Rebalance很慢。如果Consumer Group下成员很多，Rebalance一次的时间会很久。
- Rebalance效率不高。当前Kafka的设计机制决定了每次Rebalance时，Group下的所有成员都要参与进来，而且通常不会考虑局部性原理。

所以，什么时机下会发生rebalance呢？主要有三个时机：

- Consumer group组成员数量发生变化（消费者加入或退出）
- Consumer group订阅主题数量发生变化（一个consumer group订阅了多个topic）
- Consumer group订阅主题的分区数发生变化（topic增加或减少分区）

通常后两种情况是人为变更才会导致，这里我们主要讨论第一种情况：Consumer实例发生意外退出导致Consumer数量发生变化。在排查rebalance问题，我们先看监控，首先应该从天问的对应服务监控中间件-kafka监控面板出发，再关注[Kafka Consumer监控](https://grafana.corp.kuaishou.com/d/000004121/kafka-consumer-jian-kong?orgId=3)，分析出消费rebalance的原因。

下图为天问服务监控中kafka消费者rebalance指标监控面板。

下面分析了几种会导致consumer意外退出消费者组的case，针对每种case给到了具体的解决原因。日常对consumer进行扩容缩容或重启类的操作引发的rebalance不在本节讨论的case内。

### **情况1 ：consumer未及时发送心跳**

针对这个情况，要合理设置两个参数：会话超时时间[session.timeout.ms](http://session.timeout.ms/) 和心跳间隔 [heartbeat.interval.ms](http://heartbeat.interval.ms/) ，保证会话超时时间至少≥3倍的心跳时间，这样就能保证在超时前最少发3次心跳。

我手的kafka版本为0.10.2.1，会话超时时间设置为session.timeout.ms是120s，心跳间隔heartbeat.interval.ms使用的是默认值3s。（根据[Kafka-快手Kafka](https://halo.corp.kuaishou.com/help/docs/e3877e53434e09249957e2a858859e9a)和[Kafka Java client用户手册](https://docs.corp.kuaishou.com/k/home/VE5G1O1w8k8M/fcADULEEmHehaa6IzuXMa71DI#section=h.h2ynr5ucj2bh)查阅得知，如有不对，请老铁们指正）

这里值得说明一个点是，Kafka 0.10.0.0版本中心跳(heartbeats)与拉消息(poll)是耦合在一起的，只有会话超时参数session.timeout.ms，没有独立的的控制poll间隔的参数。假设session.timeout.ms =60s,  如果消费者没有在1分钟内处理完一批消息后poll下一批消息，心跳没及时随着poll发出去，就会因心跳超时而退出Consumer group。

在Kafka 0.10.1.0版本针对这个点做出了升级，心跳与poll解耦，每个线程有独立的心跳维护机制。从该版本开始新增了独立的 max.poll.interval.ms 参数（配置两次 poll 的间隔时间），也就是可以消费者会话超时时间和消费者消息处理时间可以分开配置，允许消息处理时间大于心跳时间 (会话超时时间session.timeout.ms) 。该版本中session.timeout.ms 用于维护心跳线程，默认值为10s，max.poll.interval.ms 用于消费处理线程，默认值为300s。

ps：对Kafka各版本做了哪些更新感兴趣的老铁们可以查看[https://kafka.apache.org/0102/documentation.html#newconsumerconfigs](https://kafka.apache.org/0102/documentation.html#newconsumerconfigs)

### **情况2 ：consumer消费速度太慢**

如果consumer消费速度太慢，一批消息的处理时间太长（比如上节提到的本地重试引起的），当consumer两次poll消息的时间间隔大于poll最大间隔时间max.poll.interval.ms时，consumer就会主动发出离开消费组的请求。

目前我手的配置是：max.poll.interval.ms使用的是默认间隔时间为300s，一批消息大小max.poll.records默认值为500。

那么如果线上已经出现这个问题了要如何快速止损呢？

（1）如果确定是消费能力不足，那么可增加Consumer的worker线程，具体见[https://halo.corp.kuaishou.com/help/docs/66210110d56a7b3603714fde31e427a8](https://halo.corp.kuaishou.com/help/docs/66210110d56a7b3603714fde31e427a8)。

（2）根据实际场景可将拉取消息间隔时间 max.poll.interval.ms值设置大一些

（3）根据实际场景可将一次拉取消息数max.poll.records值设置小一些

具体如何调整这些配置可见：[Kafka Java client用户手册](https://docs.corp.kuaishou.com/k/home/VE5G1O1w8k8M/fcADULEEmHehaa6IzuXMa71DI#section=h.h2ynr5ucj2bh)

### **情况3：consumer GC**

如果Consumer消费逻辑有问题，导致频繁的Full GC导致的长时间停顿，也会导致consumer异常停顿。这个就需要具体排查代码来解决了。

### **2、消费lag是什么？发生后如何处理？**

对于Kafka消费者来说，最重要的事情就是监控它们的消费进度了，或者说是监控它们消费的滞后程度。这个滞后程度有个专门的名称：**消费者Lag**或Consumer Lag。

所谓滞后程度，就是指消费者当前落后于生产者的程度。比方说，我们的系统蒸蒸日上做大做强，有许多餐饮商户都来接入了。一到饭点，消息非常多，假如生产者向broker一秒生产了10万条消息，但是这时消费者只消费了8万条消息，那么也就可以说消费者滞后了2万条消息，即Lag等于2万。

排查消费lag问题，我们可以从天问-服务监控的kafka消费者监控面板查看消费lag时长，还可以到[Kafka Lag Time监控](https://grafana.corp.kuaishou.com/d/000006190/kafka-lag-time?orgId=3&refresh=1m)查看lag时长，再关注[Kafka Consumer监控](https://grafana.corp.kuaishou.com/d/000004121/kafka-consumer-jian-kong?orgId=3)分析。

下图为天问服务大盘的消费者lag时长监控指标图。默认配置为lag时长超过300s就会告警。

下面给出了几个产生消费lag的常见原因以及对应解决方案：

（1）consumer自身消费能力不足，是常见的导致消费lag的原因，可以从以下几个方面排查消费能力的瓶颈。

- worker线程池使用率达到100%。这种一般是消费逻辑执行过慢。若消费逻辑中不存在限制并发消费能力的因素，可增加worker线程数（命令行参数为：--worker-threads）。具体见[https://halo.corp.kuaishou.com/help/docs/66210110d56a7b3603714fde31e427a8](https://halo.corp.kuaishou.com/help/docs/66210110d56a7b3603714fde31e427a8)。但是要注意，我手kafka增加 consumer实例数 * consumer线程数 < 3500的限制(broker端限制同消费组成员数不能超过3500)，一旦超过会引发频繁的rebalance。
- cpu使用率达到100%。这种情况是本身机器资源已经达到瓶颈,如果无法对消费逻辑进行优化,可考虑扩容。

（2）consumer数据拉取瓶颈，表现为consumer线程的CPU使用率至少超过50%

- 若单个consumer线程分配的partition较多,可能导致数据拉取出现瓶颈，可增加consumer主线程数，提高consumer的fetch能力。（命令行参数为：--consumer-threads）
- 若单partition的流量较大,可在[青藤平台](https://qingteng.corp.kuaishou.com/#/topics)申请增加partition

（3）consumer rebalance时会停止消费，若rebalance较频繁，也可能导致消费lag。这个解决思路见上节。

（4）producer发送partition不均匀，有单partition热点问题。建议从上游对热点数据进行优化，比如针对热点数据使用单独的topic。

（5）少数情况中也有：消费lag也可能是由于集群故障所致，在看过producer和consumer的生产消费曲线都很正常时，可以在lag监控中查看同一集群中，是否有其他topic也是在同一时间点出现lag，若有的话，多半是集群中部分节点出了故障。
