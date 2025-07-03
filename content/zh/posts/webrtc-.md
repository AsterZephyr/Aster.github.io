---
title: "WebRTC底层核心技术原理解析——从协议栈到具体实现"
date: 2025-07-02T14:25:26Z
draft: false
tags: ["WebRTC", "实时通信", "分布式系统", "系统架构", "网络协议", "网络编程", "Go语言", "性能优化", "高并发", "人工智能", "机器学习"]
author: "Aster"
description: "Created: 2025年3月11日 00:16..."
---

# WebRTC底层核心技术原理解析——从协议栈到具体实现

Created: 2025年3月11日 00:16
Status: 完成

# **什么是 WebRTC？**

WebRTC 是 Web Real-Time Communication 的缩写，既是 API 又是协议。WebRTC 协议是**两个 WebRTC 代理协商双向安全实时通信的一组规则**。WebRTC 协议在 [rtcweb](https://datatracker.ietf.org/wg/rtcweb/documents/) 工作组的 IETF 中维护。WebRTC API 在 W3C 中记录为 [webrtc](https://www.w3.org/TR/webrtc/)。

可能大家用过微信视频或者腾讯会议，但 WebRTC 的底层流程其实非常复杂。它涉及到摄像头调用、网络穿透、加密传输等等。今天我会用“**快递送包裹”**的比喻，拆解它的核心步骤。

# **WebRTC 协议是其他技术的集合**

[](https://docs.corp.kuaishou.com/image/api/external/load/out?code=fcAB7PwjKm4SKxZ3TGFZTMwX-:8137911488324557019fcAB7PwjKm4SKxZ3TGFZTMwX-:1741625199674)

WebRTC 协议是一个巨大的话题，需要一整本书来解释。但是，首先，我们将其分为四个步骤。

1. 信令
2. 连接
3. 安全
4. 沟通

这些步骤是连续的，这意味着上一步必须 100% 成功，后续步骤才能开始。

[](https://docs.corp.kuaishou.com/image/api/external/load/out?code=fcAB7PwjKm4SKxZ3TGFZTMwX-:-6950310192179471767fcAB7PwjKm4SKxZ3TGFZTMwX-:1741625199674)

[](https://docs.corp.kuaishou.com/image/api/external/load/out?code=fcAB7PwjKm4SKxZ3TGFZTMwX-:-653116334979560233fcAB7PwjKm4SKxZ3TGFZTMwX-:1741625199674)

### **第一步：设备权限——先找到“摄像头和麦克风”**

想象一下，你要寄快递，首先得知道包裹在哪儿

- **WebRTC 的第一步**就是调用设备的摄像头和麦克风。
- 浏览器会弹窗问用户：“是否允许使用摄像头？”（这时候用户要是点了拒绝，后面全白搭）

前端代码里用的是 getUserMedia 这个 API，比如：

- 
    
    ```
    const stream = await navigator.mediaDevices.getUserMedia({ video: true, audio: true });
    ```
    

这一步拿到的是一个原始数据流（MediaStream），目前你拿到了包裹，但还不知道怎么寄出去。

### **第二步：信令交换：对等体如何在 WebRTC 中找到彼此（寄包裹地址）**

现在你要把包裹寄给朋友，但你们还不认识，怎么办？

- WebRTC 需要一个中间人（信令服务器）来交换联系方式。
- 这个中间人可以用 WebSocket 或者 HTTP 长连接实现（比如用 [Socket.io](http://socket.io/)）。
- 双方会通过它交换两个关键信息：
    1. **SDP（会话描述协议）**：类似快递单，写清楚“包裹类型”（比如视频用 VP8 编码）、收件地址（IP 和端口）。
    2. **ICE 候选**：相当于多个可能的快递路线（比如顺丰、中通）。

**信令**使用一种称为 **SDP（**Session Description Protocol**-会话描述协议）**的现有纯文本协议。每个 SDP 消息都由**键/值对**组成，并包含一个“**媒体部分”列表**。两个 WebRTC 代理交换的 SDP 包含如下详细信息：

- 可访问代理的 IP 和端口 （候选项）。
- 代理希望发送的音频和视频轨道的数量。
- 每个代理支持的音频和视频编解码器。
- 连接时使用的值 （uFrag/uPwd）
- 保护时使用的值（证书指纹）。

[](https://docs.corp.kuaishou.com/image/api/external/load/out?code=fcAB7PwjKm4SKxZ3TGFZTMwX-:4935451272181110901fcAB7PwjKm4SKxZ3TGFZTMwX-:1741625199675)

时序图中我们也可以看出，初始阶段两个peer都需要跟信令服务器相连，在一端发起会话邀请以后，需要通过信令服务器传递offer，answer和candidate信息，最终要根据sdp协商情况，打洞情况决定是否能实现p2p链接。

需要注意的是，信令通常是“**带外**”发生的，这意味着应用程序通常不使用 WebRTC 本身来交换信令消息。在发起 WebRTC 连接之前，双方之间需要有**另一个通信通道**。使用的通道类型不是 WebRTC 关心的问题。任何适合发送消息的架构都可以在连接的对等体之间中继 SDP，许多应用程序将简单地使用其现有的基础设施（例如 REST 端点、WebSocket 连接或身份验证代理）来促进适当客户端之间的 **SDP 交易**。

[](https://docs.corp.kuaishou.com/image/api/external/load/out?code=fcAB7PwjKm4SKxZ3TGFZTMwX-:7116923681389097682fcAB7PwjKm4SKxZ3TGFZTMwX-:1741625199675)

SDP示例：

[](https://docs.corp.kuaishou.com/image/api/external/load/out?code=fcAB7PwjKm4SKxZ3TGFZTMwX-:-3984795209816463177fcAB7PwjKm4SKxZ3TGFZTMwX-:1741625199675)

### **第三步：网络穿透——找到能通的“快递路线”**

[](https://docs.corp.kuaishou.com/image/api/external/load/out?code=fcAB7PwjKm4SKxZ3TGFZTMwX-:-4831837078366144809fcAB7PwjKm4SKxZ3TGFZTMwX-:1741625199675)

### **一、ICE框架的角色与核心逻辑**

ICE（Interactive Connectivity Establishment） 是WebRTC实现NAT穿透的核心协议框架，其核心目标是通过**多路径探测**与**优先级排序**，找到**最优通信路径**，确保P2P连接的建立。以下是其核心逻辑：

1. **候选地址（Candidate）管理**

类型：分为Host（本地地址）、Srflx（STUN反射地址）、Relay（TURN中继地址）三类。

优先级公式：优先级 = (2^24 * 类型权重) + (2^8 * 本地偏好) + 端口号，

Host (Host Candidate)> Prflx(Peer Reflexive Candidate)>Srflx(Server Reflexive Candidate) > Relay

生成方式：

- Host候选通过本地网卡直接获取。
- Prflx候选 并非通过主动请求生成，而是在连通性检查过程中，由对端发送的STUN请求中发现
- Srflx候选通过STUN服务器获取NAT映射地址。
- Relay候选通过TURN服务器分配中继地址。

[](https://docs.corp.kuaishou.com/image/api/external/load/out?code=fcAB7PwjKm4SKxZ3TGFZTMwX-:-987392705933430958fcAB7PwjKm4SKxZ3TGFZTMwX-:1741625199675)

1. **状态机与连通性检查**

状态流转：候选对（Local/Remote）按优先级经历Frozen → Waiting → In-Progress → Succeeded/Failed状态。

双向探测：双方通过STUN Binding请求互相发送探测包，触发NAT映射表项（UDP Hole Punching）。

超时机制：若500ms未收到响应，切换下一候选对

**具体流程：**

**例子：**

[](https://docs.corp.kuaishou.com/image/api/external/load/out?code=fcAB7PwjKm4SKxZ3TGFZTMwX-:1674252542587478881fcAB7PwjKm4SKxZ3TGFZTMwX-:1741625199675)

**交换候选地址**

A通过信令服务器把A$Cand1、A$Cand2、A$Cand3发向B，相应地，B通过信令服务器把B$Cand1、B$Cand2、B$Cand3发向A。对端收到一个候选地址后会做什么？深入它之前让引入两种对象：[P2PTransportChannel](https://zhida.zhihu.com/search?content_id=2221392&content_type=Article&match_order=1&q=P2PTransportChannel&zhida_source=entity)、[Connection](https://zhida.zhihu.com/search?content_id=2221392&content_type=Article&match_order=1&q=Connection&zhida_source=entity)。

ICE代理用P2PTransportChannel管理通道（Component）上的网络传输。什么是通道？Webrtc有个概念叫轨道（Track），常见有视频轨、音频轨，而要发送一条轨道中数据，最多可能使用两个通道，分别是Rtp、Rtcp。肯定会有Rtp，Rtcp则可选。一个P2PTransportChannel对应一条通道，如果当前会话要同时处理音频、视频，每条轨道又都包括Rtp、Rtcp，那会话中就存在四个P2PTransportChannel对象。P2PTransportChannel用维护一张连接状态表来管理网络传输，表中一条记录对应一个Connection对象。这里让具体到A的视频Rtp对应的P2PTransportChannel，看它在收到B$Cand1后会做什么。

当A收到B发来的B$Cand1后，P2PTransportChannel会向连接状态表新增两条记录，即两个Connection。这时已到通道，地址须是ip:port对。

[](https://docs.corp.kuaishou.com/image/api/external/load/out?code=fcAB7PwjKm4SKxZ3TGFZTMwX-:2243862444528337112fcAB7PwjKm4SKxZ3TGFZTMwX-:1741625199675)

此时A不知道该用哪个网卡IP才能把数据成功发向192.168.0.204，于是它只要在有可能的地址对就创建Connection。注意Connection只会基于网卡IP，即host，因为对发送源来说，host才可能是源，其它的只是中间转换出的地址，像srflx。当然，创建时会放弃明显不可能的<网卡地址, 对端地址>对，举个例子，网卡地址是ipv4，而对端地址是ipv6。

当收全B$Cand1、B$Cand2、B$Cand3，状态表中就有6条记录。

[](https://docs.corp.kuaishou.com/image/api/external/load/out?code=fcAB7PwjKm4SKxZ3TGFZTMwX-:8355785275910757053fcAB7PwjKm4SKxZ3TGFZTMwX-:1741625199675)

表中有一条、或多条、或没有，能够把A的视频Rtp数据发向B的视频Rtp通道，到底怎么个可能性就要执行接下的Stun检查。

**STUN检查**

在状态表新建一条记录，即一个Connection，很快就会在此Connection上进行Stun检查。Stun检查具体操作是在此Connection上发[Stun Binding请求](https://zhida.zhihu.com/search?content_id=2221392&content_type=Article&match_order=1&q=Stun+Binding%E8%AF%B7%E6%B1%82&zhida_source=entity)。**由于要能支持Stun应答，每个ICE代理必须内置[Stun服务器](https://zhida.zhihu.com/search?content_id=2221392&content_type=Article&match_order=1&q=Stun%E6%9C%8D%E5%8A%A1%E5%99%A8&zhida_source=entity)功能。**Stun检查具体步骤见下图。

[](https://docs.corp.kuaishou.com/image/api/external/load/out?code=fcAB7PwjKm4SKxZ3TGFZTMwX-:-6442581009068997405fcAB7PwjKm4SKxZ3TGFZTMwX-:1741625199675)

为什么说Stun检查会发现prflx候选项？假如A和Stun服务器之间连接状态不好，在它收到B发来的srflx（11.92.14.8）之后还没得出自个的srflx（211.161.240.181）。虽然A没得到自个的srflx，但这不妨碍对B的srflx这个候选地址进行Stun检查，于是会向11.92.14.8发Stun请求。B收到这个请求，从请求解析出211.161.240.181。虽然这个地址在值上等于A的srflx，但不是从信令服务器得到，而是来自对端的Stun请求。此时B就会以这个prflx向状态表新建Connection。

A在之后终于向Stun服务器拿到了自个的srflx，并通过信令服务器发向B。B发现这个srflx值对应的Connection已存在，就不会再创建了。

到此可得出个结论：两种原因会导致新建Connection，一是从信令服务器收到候选地址，二是Stun检查发现prflx。不同于从信令服务器得到地址而创建的Connection，Stun检查时创建的Connection一开始就基本能确定连接是畅通的。

1. **路径选择与收敛**

成功标志：首个通过验证的候选对被标记为Succeeded，后续候选终止检查。

动态优化：根据RTCP反馈（如丢包率）动态调整候选优先级。

[](https://docs.corp.kuaishou.com/image/api/external/load/out?code=fcAB7PwjKm4SKxZ3TGFZTMwX-:-2272775079815152580fcAB7PwjKm4SKxZ3TGFZTMwX-:1741625199676)

### **二、STUN协议：NAT穿透的基石**

**STUN**(Session Traversal Utilities for NAT,NAT会话穿越应用程序)是一种网络协议，它允许位于NAT(或多重NAT)后的客户端**找出自己的公网地址**，查出自己位于哪种类型的NAT之后以及NAT为某一个本地端口所**绑定的Internet端口**。这些信息被用来在两个同时处于NAT路由器之后的主机之间创建UDP通信。该协议由RFC5389定义。在遇到上述情况的时候，我们可以建立一个STUN服务器，这个服务器做什么用的呢？主要是给**无法在公网环境**下的视频通话设备**分配公网IP**用的。这样两台电脑就可以在公网P中进行通话。（公网发现，维持NAT）

1. **核心交互流程**

**Binding请求/响应：客户端发送请求至STUN服务器，服务器返回XOR-MAPPED-ADDRESS字段（包含客户端公网IP和端口）。**

**报文结构：**

- **`STUN Header (20字节)
+ Magic Cookie (0x2112A442)
+ Transaction ID (96位随机数)
+ Attributes (如XOR-MAPPED-ADDRESS、MESSAGE-INTEGRITY)`**
- **安全与保活机制**
    - **HMAC-SHA1校验：通过MESSAGE-INTEGRITY属性验证消息完整性，密钥由uFrag/uPwd生成。**
    - **定期保活：每15秒发送STUN Binding请求，防止NAT映射表项过期。**
- **NAT类型判定**
    - **通过向多台STUN服务器发送请求，对比返回地址差异，判断NAT类型（如对称型、锥型）。**

**使用一句话说明STUN做的事情就是：告诉我你的公网IP地址+瑞口是什么。搭建STUN服务器很简单，媒体流传输是按照P2P的方式。那么问题来了，STUN并不是每次都能成功的为需要NAT的通话设备分配P地址的，P2P在传输媒体流时，使用的本地带宽，在多人视频通话的过程中，通话质量的好坏往往需要将据使用者本地的带宽确定。那么怎么办？TURN可以很好的解决这个问题**

### **三、TURN协议：穿透失败的终极保障**

**TURN**的全称为Traversal Using Relays around NAT,是STUN/RFC5389的一个拓展，主要添加了**Relay功能**。如果终端在NAT之后，那么在特定的情景下有可能使得终瑞无法和其对等端(Peer)进行直接的通信，这时就需要公网的服务器作为一个中继，对来往的数据进行转发。这个转发的协议就被定义为 TURN.

1. **核心机制**

**分配阶段：客户端发送Allocate请求，TURN服务器分配RELAYED-ADDRESS（如54.198.76.12:3478）。**

**转发机制：**

**Relay模式：通过STUN封装的Send/Data Indication传输数据，增加36字节头部。**

**Channel模式：使用4字节头部（ChannelData），减少协议开销，适用于音视频流。**

**权限控制：客户端需通过CreatePermission授权对端IP，防止未认证访问。**

1. **性能优化**

**多路复用：单个中继地址支持多对端通信，降低服务器负载。**

**带宽控制：TURN服务器可动态调整转发速率，避免拥塞。**

### **四、ICE与STUN/TURN的协同流程**

1. **候选收集阶段**

客户端同时向STUN和TURN服务器发起请求，生成Host、Srflx、Relay候选地址。

**优先级排序**：Host > Srflx > Relay，按公式计算综合优先级。

1. **连通性检查阶段**

**直连优先**：优先尝试Host和Srflx候选对，通过STUN Binding触发NAT打洞。

**中继回退**：若对称型NAT导致直连失败，启用Relay候选通过TURN中继传输。

1. **路径锁定与加密**

首个成功候选对建立后，启动DTLS握手生成加密密钥。

媒体流通过SRTP加密，数据通道通过SCTP传输。

### **五、典型穿透场景分析**

| **场景** | **候选类型** | **协议作用** |
| --- | --- | --- |
| **局域网内通信** | Host-Host | 直接通过本地IP建立连接，延迟最低（<5ms）。 |
| **锥型NAT穿透** | Srflx-Srflx | STUN获取公网地址，双向触发NAT映射表项。 |
| **对称型NAT穿透** | Relay-Relay | TURN中继强制转发，牺牲延迟（50-200ms）保障连通性。 |
| **混合网络（跨运营商）** | Srflx-Relay | ICE自动选择最优路径，优先直连失败后切换中继。 |

### **第四步：安全加密 使用 DTLS 和 SRTP 保护传输层**

现在我们已经有了**双向通信（通过 ICE）**，我们需要确保我们的**通信安全**。这是通过另外两个协议完成的，这两个协议也早于 WebRTC;

**DTLS**（数据报传输层安全性）和 **SRTP**（安全实时传输协议）。

第一种协议 DTLS 只是**基于 UDP 的 TLS**（TLS 是用于保护 HTTPS 通信的加密协议）。第二种协议 SRTP 用于确保 **RTP**（实时传输协议）**数据包的加密**。

首先，WebRTC 通过在 ICE 建立的连接上进行 DTLS 握手来连接。与 HTTPS 不同，WebRTC 不对证书使用中央颁发机构。它只是**断言**通过 **DTLS 交换的证书**与通过信令共享的**指纹匹配**。然后，此 DTLS 连接将用于 DataChannel 消息。

接下来，WebRTC 使用使用 **SRTP 保护的 RTP 协议**进行音频/视频传输。我们通过从协商的 DTLS 会话中**提取密钥**来初始化 **SRTP 会话。**

**在这两个协议之前 SDP和STUN也会做一些安全校验：**

通过媒体协商交换SDP信息，在 SDP 中记录了用户的用户名、密码、指纹

STUN协议进行身份认证，确认用户是否为合法用户

进行DTLS协商，交换公钥证书以及协商密码相关的信息，同时还要通过 fingerprint 对证书进行验证，确认其没有在传输中被篡改。

将RTP协议升级为SRTP协议进行加密传输

**交换的SDP信息-安全描述**

[](https://docs.corp.kuaishou.com/image/api/external/load/out?code=fcAB7PwjKm4SKxZ3TGFZTMwX-:3702945541395039416fcAB7PwjKm4SKxZ3TGFZTMwX-:1741625199677)

**STUN协议作用**

- **获取公网 IP 和端口**
- **在 TURN 协议中发送 Allocation 指令，得到 TURN 服务器的地址**
- **身份认证**

接下来我们来看看他是如何进行身份认证的

它主要是通过 HMAC 来实现，HMAC 是哈希运算消息认证码，我们可以通过他进行消息完整性认证和信源身份认证，而我们对双方进行身份认证判断他是不是合法用户其实就是信源身份认证的过程。

信源身份认证主要是因为通信双方共享了认证的密钥，接收方验证发送过来的消息，判断计算的 HMAC 值和发送过来的消息中的 HMAC 值是否一致，从而确定发送方的身份合法性。

HMAC运算利用hash算法，以一个消息M和一个密钥K作为输入，生成一个定长的消息摘要作为输出。

[](https://docs.corp.kuaishou.com/image/api/external/load/out?code=fcAB7PwjKm4SKxZ3TGFZTMwX-:613483407704778342fcAB7PwjKm4SKxZ3TGFZTMwX-:1741625199677)

### **DTLS 协议**

DTLS（Datagram Transport Level Security，数据报安全协议），基于 UDP 场景下数据包可能丢失或重新排序的现实情况，为 UDP 定制和改进的 TLS 协议。DTLS 提供了 UDP 传输场景下的安全解决方案，能防止消息被窃听、篡改、身份冒充等问题。在 WebRTC 中使用 DTLS 的地方包括两部分：协商和管理 [SRTP]() 密钥和为 [DataChannel]() 提供加密通道。

DTLS 协议能够做到以下几点：

- 所有信息通过加密传播，第三方无法窃听；
- 具有数据签名及校验机制，一旦被篡改，通信双方立刻可以发现；
- 具有身份证书，防止其他人冒充。

**协议栈**

在 WebRTC 中，通过引入 DTLS 对 RTP 进行加密，使得媒体通信变得安全。通过 DTLS 协商出加密密钥之后，RTP 也需要升级为 SRTP，通过密钥加密后进行通信。协议栈如下图所示：

[](https://docs.corp.kuaishou.com/image/api/external/load/out?code=fcAB7PwjKm4SKxZ3TGFZTMwX-:7424612677779736621fcAB7PwjKm4SKxZ3TGFZTMwX-:1741625199677)

DTLS 握手协议流程如下，（参考 RFC6347）。

[](https://docs.corp.kuaishou.com/image/api/external/load/out?code=fcAB7PwjKm4SKxZ3TGFZTMwX-:-709503173784868630fcAB7PwjKm4SKxZ3TGFZTMwX-:1741625199677)

webRTC虽然是P2P连接，但是会在交换SDP的时，通过a=setup:xxx的方式，来声明当前Agent在DTLS协商时的身份是client还是server, 从而来确定握手的主从顺序

[](https://docs.corp.kuaishou.com/image/api/external/load/out?code=fcAB7PwjKm4SKxZ3TGFZTMwX-:-8672415530513808382fcAB7PwjKm4SKxZ3TGFZTMwX-:1741625199677)

TLS 和 DTLS 的握手过程基本上是一致的，差别以及特别说明如下：

- DTLS 中 HelloVerifyRequest 是为防止 DoS 攻击增加的消息。
- TLS 没有发送 CertificateRequest，这个也不是必须的，是反向验证即服务器验证客户端。
- DTLS 的 [RecordLayer](https://zhida.zhihu.com/search?content_id=199680187&content_type=Article&match_order=1&q=RecordLayer&zhida_source=entity) 新增了 Epoch 和 SequenceNumber；[ClientHello](https://zhida.zhihu.com/search?content_id=199680187&content_type=Article&match_order=1&q=ClientHello&zhida_source=entity) 中新增了 Cookie；Handshake 中新增了 Fragment 信息（防止超过 UDP 的 MTU），都是为了适应 UDP 的丢包以及容易被攻击做的改进。（参考 RFC 6347）
- DTLS 最后的 Alert 是将客户端的 Encrypted Alert 消息，解密之后直接响应给客户端的，实际上 Server 应该回应加密的消息，这里我们的服务器回应明文是为了解析客户端加密的那个 Alert 包是什么。

RecordLayer 协议是和 DTLS 传输相关的协议，UDP 上是 RecordLayer，RecordLayer 上是 Handshake 或 ChangeCipherSpec 或 ApplicationData。

RecordLayer 协议定义参考 RFC4347，实际上有三种 RecordLayer 的包:

- DTLSPlaintext，DTLS 明文的 RecordLayer。
- DTLSCompressed，压缩的数据，一般不用。
- DTLSCiphertext，加密数据，在 ChangeCipherSpec 之后就是这种了。

没有明确的字段说明是哪种消息，不过可以根据上下文以及内容判断。比如 ChangeCipherSpec 是可以通过类型，它肯定是一个 Plaintext。除了 Finished 的其他握手，一般都是 Plaintext。

### **SRTP 密钥协商**

**1、SDP 交换与角色协商**

**a=setup**：协商 DTLS 角色（Client/Server），通过 active/passive/actpass 确定握手发起方。

示例：a=setup:active 表示本端作为 DTLS Client 主动发起握手。

**a=fingerprint**：交换自签名证书的 SHA-256 哈希值，用于身份验证（RFC4572）。

示例：a=fingerprint:sha-256 49:66:12:17:0D:1C...

[](https://docs.corp.kuaishou.com/image/api/external/load/out?code=fcAB7PwjKm4SKxZ3TGFZTMwX-:670632755020941225fcAB7PwjKm4SKxZ3TGFZTMwX-:1741625199677)

**2、DTLS 握手**

**ClientHello/ServerHello**：

**版本**：协商 DTLS 版本（如 DTLS 1.2）。

**加密套件**：选择算法（如 TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256）。

**扩展协议**：启用 use_srtp 扩展（RFC5764），声明 SRTP 配置（如 SRTP_AES128_CM_HMAC_SHA1_80）。

**证书验证**：比对 SDP 中的指纹与 DTLS 证书哈希，防止中间人攻击。

[](https://docs.corp.kuaishou.com/image/api/external/load/out?code=fcAB7PwjKm4SKxZ3TGFZTMwX-:4643719501848968499fcAB7PwjKm4SKxZ3TGFZTMwX-:1741625199677)

**3、密钥交换（ECDHE）**

**Server/Client Key Exchange**：交换椭圆曲线公钥（Spk 和 Cpk）。

基于 ECDH 算法，双方计算共享密钥 pre_master_secret。

公式：S = Ds * Cpk = Dc * Spk（Ds 和 Dc 为私钥）。

[](https://docs.corp.kuaishou.com/image/api/external/load/out?code=fcAB7PwjKm4SKxZ3TGFZTMwX-:-7078758631591742395fcAB7PwjKm4SKxZ3TGFZTMwX-:1741625199677)

**4、主密钥与 SRTP 密钥导出**

- **计算 master_secret**：
- 
    
    ```
    master_secret = PRF(pre_master_secret, "master secret", client_random + server_random)[0:48]
    ```
    
- **生成 SRTP 密钥块**：
- 
    
    ```
    Python
    key_block = PRF(master_secret, "EXTRACTOR-dtls_srtp", client_random + server_random)[0:60]
    ```
    

**分割密钥块**：

- client_write_key（16B） + server_write_key（16B）
- client_salt（14B） + server_salt（14B）

[](https://docs.corp.kuaishou.com/image/api/external/load/out?code=fcAB7PwjKm4SKxZ3TGFZTMwX-:3501141340847621251fcAB7PwjKm4SKxZ3TGFZTMwX-:1741625199677)

**5、SRTP 加密初始化**

- **配置 SRTP 会话**：
    - 使用 client_write_key + client_salt 加密发送数据。
    - 使用 server_write_key + server_salt 解密接收数据。
- **加密媒体流**：通过 AES-CM 加密 RTP 包，HMAC-SHA1 验证完整性。

**对于RTP/RTCP的保护流程大体如下**

**Sender 发送者：**

1. 如有需要, 重新生成主密钥
2. 从主密钥 master key 中派生会话密钥 session key
3. 加密有效负载 payload
4. 计算验证标签 authenticate tag
5. 更新SRTP包的 payload 为加密内容, 并添加 authenticate tag

**Receiver 接受者：**

1. 如有需要, 重新生成主密钥
2. 从主密钥 master key 中派生会话密钥 session key
3. 重放保护 Replay protect
4. 验证数据包 Authenticate packet
5. 解密有效负载
6. 更新 Rollover Count
7. 更新重放列表 replay list
8. 删除 MKI 和验证标签 authenticate tag

[](https://docs.corp.kuaishou.com/image/api/external/load/out?code=fcAB7PwjKm4SKxZ3TGFZTMwX-:809047572106685638fcAB7PwjKm4SKxZ3TGFZTMwX-:1741625199678)

### **第五步：实时传输——开始“送包裹”**

当两个 WebRTC 代理完成安全连接后，真正的实时通信就开始了，这一步就像快递员终于开始派送包裹，但需要两种不同的“运输工具”来分别处理音视频和数据：

### **音视频传输：RTP（实时传输协议）**

[](https://docs.corp.kuaishou.com/image/api/external/load/out?code=fcAB7PwjKm4SKxZ3TGFZTMwX-:-1707014969868743989fcAB7PwjKm4SKxZ3TGFZTMwX-:1741625199678)

- 核心作用：将音视频数据切割成小包，像快递员分装包裹一样，每个包标上序号和时间戳。
- 关键特性：

低延迟优先：不保证100%送达（允许丢包），但确保数据包快速到达。

灵活适应网络：开发者可根据需求调整抗丢包策略（比如重传或直接丢弃旧包）。

加密增强版（SRTP）：音视频数据通过 SRTP 加密，防止被窃听或篡改。

监控助手（RTCP）： 它的主要目的就是基于度量来控制 **RTP** 的传输来改善实时传输的性能和质量, 它主要有5种类型的RTCP包：

1. RR接收者报告Receiver Report

2. SR发送者报告 Sender Report

3. SDES数据源描述报告 Source DEScription

4. BYE 告别报告 Goodbye

5. APP 应用程序自定义报告 Application-defined packet

RR, SR, SDES 可用来汇报在数据源和目的之间的多媒体传输信息, 在报告中包含一些统计信息, 比如 **RTP**包 发送的数量, **RTP**包丢失的数量, 数据包到达的抖动, 通过这些报告, 应用程序就可以修改发送速率, 也可做一些其他调整以及诊断。

[](https://docs.corp.kuaishou.com/image/api/external/load/out?code=fcAB7PwjKm4SKxZ3TGFZTMwX-:-3099821467460127575fcAB7PwjKm4SKxZ3TGFZTMwX-:1741625199678)

定期发送控制包（如：“你那边丢包率5%！”），让双方动态调整码率或分辨率。

类似快递公司的“物流监控系统”，实时反馈运输状态。

举个例子： 视频通话中，如果网络变差，WebRTC 可能自动降低分辨率（从1080P→720P），避免卡顿。

### **数据通道：SCTP（流控制传输协议）**

核心作用：传输非音视频数据（文件、文字、游戏指令），类似“快递送文件”。

RTCDataChannel 接口表示一个网络通道，可用于任意数据的**双向对等传输**。 每个数据通道都与一个 **RTCPeerConnection** 相关联，每个对等连接理论上最多可以有 65,534 个数据通道（实际限制可能因浏览器而异）。

发起方如果要创建数据通道并要求远程对等方加入您，可调用 RTCPeerConnection 的 createDataChannel() 方法。 应答方会接收到一个数据通道事件 (其类型为 RTCDataChannelEvent), 以告知其数据通道已添加到连接中。

Data Channel 背后使用的协议是 **SCTP**

数据通信通过 TCP/TLS 就足够了， 为什么还要 **SCTP**, 可能是因为 TCP 是面向流的，始终有序和可靠的传输，而我们还想要一种面向消息的，并且可以控制优先级和可靠性的连接， 乱序或者有点丢失也能接受。

**SCTP** 是基于 DTLS 之上的， 面向消息的， 支持多流，优先级及可靠性可控的连接协议。

假设我们通过一个连接传送流媒体以及控制命令，如果通过 TCP , 包丢失了就要重传，乱序了也一样。**SCTP** 就可以不一样，流媒体的包可以丢失，控制命令的包不能丢失

**关键特性：**

- 使用 TCP 友好的拥塞控制。
- 可修改的拥塞控制，用于与 SRTP 媒体流拥塞控制集成。
- 支持多个单向流，每个流都提供自己的有序消息传递概念。
- 支持有序和无序消息传递。
- 通过提供分段和重组来支持任意大小的用户消息。
- 支持 PMTU 发现。
- 支持可靠或部分可靠的消息传输。

举个栗子： 在线协作白板中，绘图指令用不可靠模式快速发送，而文件上传用可靠模式确保完整。

SCTP 关联状态机是协议可靠性和灵活性的基石。它通过状态转换规则，确保连接在复杂网络环境下（如 NAT 穿透、丢包、抖动）仍能安全建立、高效传输和终止。下图展示了SCTP 关联从初始化到关闭的全生命周期状态流转，其中关键机制包括：

- 四步握手（防 DoS 攻击）
- 双定时器管理（防资源泄漏）
- 多关闭阶段（数据完整性保障）

### **SCTP系列关联状态图**

[](https://docs.corp.kuaishou.com/image/api/external/load/out?code=fcAB7PwjKm4SKxZ3TGFZTMwX-:2806250370252037969fcAB7PwjKm4SKxZ3TGFZTMwX-:1741625199679)

相关解释：

### **1. 初始状态：CLOSED**

- **含义**：未建立关联或关联已终止。
- **触发事件**：
    - **收到 INIT 消息**：启动关联建立流程，生成 Cookie，发送 **INIT ACK**，进入 **COOKIE-WAIT** 状态。
    - **收到 ABORT 消息**：直接删除传输控制块（TCB），保持 **CLOSED**。

### **2. 关联建立阶段**

### **状态1：COOKIE-WAIT**

- **含义**：等待对端返回 **COOKIE ECHO**。
- **触发事件**：
    - **发送 INIT ACK 后**：启动初始化定时器（等待对端响应）。
    - **收到有效的 COOKIE ECHO**（携带正确 Cookie）：
        - 创建 TCB，发送 **COOKIE ACK**，进入 **ESTABLISHED**（关联建立成功）。
    - **初始化定时器超时**：回到 **CLOSED**。

**状态2：COOKIE-ECHOED**

- **含义**：已发送 **COOKIE ECHO**，等待对端确认。
- **触发事件**：
    - **收到 COOKIE ACK**：停止 Cookie 定时器，进入 **ESTABLISHED**。
    - **Cookie 定时器超时**：回到 **CLOSED**。

### **3. 关联已建立：ESTABLISHED**

- **含义**：SCTP 关联成功建立，可正常传输数据块（DATA chunks）。
- **触发事件**：
    - **主动发起关闭**（发送 SHUTDOWN）：进入 **SHUTDOWN-PENDING**，检查未完成数据块。
    - **收到 SHUTDOWN 消息**：进入 **SHUTDOWN-RECEIVED**，检查未完成数据块。

### **4. 关联终止阶段**

### **状态3：SHUTDOWN-PENDING**

- **含义**：等待未完成数据块处理完毕，准备发送 **SHUTDOWN**。
- **触发事件**：
    - **无未完成数据块**：发送 **SHUTDOWN**，启动关闭定时器，进入 **SHUTDOWN-SENT**。

**状态4：SHUTDOWN-SENT**

- **含义**：已发送 **SHUTDOWN**，等待对端确认。
- **触发事件**：
    - **收到 SHUTDOWN ACK**：
        - 发送 **SHUTDOWN COMPLETE**，删除 TCB，回到 **CLOSED**。
    - **关闭定时器超时**：重传 **SHUTDOWN**。

**状态5：SHUTDOWN-RECEIVED**

- **含义**：收到对端 **SHUTDOWN**，需确认处理。
- **触发事件**：
    - **无未完成数据块**：发送 **SHUTDOWN ACK**，启动关闭定时器，进入 **SHUTDOWN-ACK-SENT**。

### **状态6：SHUTDOWN-ACK-SENT**

- **含义**：已发送 **SHUTDOWN ACK**，等待最终确认。
- **触发事件**：
    - **收到 SHUTDOWN COMPLETE**：删除 TCB，回到 **CLOSED**。
    - **关闭定时器超时**：重传 **SHUTDOWN ACK**。

### **5. 异常终止**

- **触发事件**：
    - **收到 ABORT 消息**：立即终止关联，删除 TCB，回到 **CLOSED**。
    - **主动发送 ABORT**：直接删除 TCB，回到 **CLOSED**。

### **关键机制**

1. **Cookie 验证**：防止拒绝服务攻击（DoS），确保关联请求合法。
2. **四次握手**（INIT → INIT ACK → COOKIE ECHO → COOKIE ACK）：比 TCP 三次握手更安全。
3. **优雅关闭**（Graceful Shutdown）：确保所有数据块传输完毕后再终止关联。
4. **定时器管理**：处理网络延迟或丢包，避免无限等待。

### **与 TCP 状态机对比**

| **状态** | **SCTP 行为** | **TCP 等效状态** |
| --- | --- | --- |
| CLOSED | 初始或终止状态 | CLOSED |
| COOKIE-WAIT | 等待对端返回 Cookie | SYN-SENT |
| ESTABLISHED | 数据正常传输 | ESTABLISHED |
| SHUTDOWN-PENDING | 等待未完成数据处理 | FIN-WAIT-1 |
| SHUTDOWN-SENT | 已发送关闭请求，等待确认 | FIN-WAIT-2 |

### 为什么这样设计？

WebRTC 的协议选择完全服务于实时性优先：

- RTP 牺牲可靠性换取速度：视频丢几帧总比卡成PPT强！
- SCTP 灵活配置：开发者根据场景选择“速度”或“可靠性”，

**以上协议在demo具体应用如下图**

[](https://docs.corp.kuaishou.com/image/api/external/load/out?code=fcAB7PwjKm4SKxZ3TGFZTMwX-:6067661940084577243fcAB7PwjKm4SKxZ3TGFZTMwX-:1741625199681)

## WebRTC的核心分层架构（从理论到实践）

## 

[](https://docs.corp.kuaishou.com/image/api/external/load/out?code=fcAB7PwjKm4SKxZ3TGFZTMwX-:-2147391321201802550fcAB7PwjKm4SKxZ3TGFZTMwX-:1741625199681)

## 结合具体demo的实战演示
