# iptables原理

Created: 2025年1月23日 15:46
Status: 完成

### 1. **iptables概述**

`iptables` 基于 Linux 内核的 Netfilter 框架，它主要用于对网络流量进行过滤、转发、修改等操作。Netfilter 提供了四种操作表：

- **Filter 表**：默认表，主要用于数据包的过滤。
- **NAT 表**：用于网络地址转换，如源地址转换（SNAT）和目标地址转换（DNAT）。
- **Mangle 表**：用于修改数据包的头部信息，如修改 TOS（Type of Service）字段，TTL（Time to Live）字段等。
- **Raw 表**：用于配置数据包的连接跟踪，通常用于绕过 Netfilter 的连接跟踪功能。

### 2. **iptables的工作原理**

`iptables` 根据规则来决定数据包的去向。每个数据包在通过网络栈时，都会经过不同的处理阶段。`iptables` 通过配置规则决定如何处理这些数据包。规则按链（Chain）顺序应用，决定数据包是否被丢弃、允许、转发或者进行地址转换。

### **链（Chain）**

每个表下都有几个预定义的链。链是一系列规则的集合，规则按顺序匹配数据包，匹配成功的规则会执行相应的动作。每个表包含不同的链，`iptables` 中有 **五个链**，它们分别是：

- **INPUT 链**：处理进入本机的数据包。
- **OUTPUT 链**：处理从本机发出的数据包。
- **FORWARD 链**：处理通过本机转发的数据包（不论是进入还是出去的）。
- **PREROUTING 链**：处理在路由决策之前到达的数据包，常用于 NAT 转换（如 DNAT）。
- **POSTROUTING 链**：处理路由决策之后离开本机的数据包，常用于源地址转换（如 SNAT）。

### **表（Table）**

iptables 支持不同的表，每个表包含不同的链，表的工作方式如下：

- **filter 表**：这是默认表，主要用于过滤数据包。`INPUT`、`OUTPUT` 和 `FORWARD` 链都属于 `filter` 表。
- **nat 表**：用于地址转换（NAT）。`PREROUTING`、`POSTROUTING` 和 `OUTPUT` 链属于 `nat` 表。
- **mangle 表**：用于修改数据包的内容（例如，TTL、TOS 字段）。`PREROUTING`、`POSTROUTING`、`INPUT`、`OUTPUT` 和 `FORWARD` 链都属于 `mangle` 表。
- **raw 表**：用于配置连接跟踪的设置。`PREROUTING` 和 `OUTPUT` 链属于 `raw` 表。

### 3. **iptables 规则的底层实现**

`iptables` 是基于 **Netfilter** 框架实现的，Netfilter 是一个 Linux 内核模块，它提供了一个接口，允许程序（如 `iptables`）来定义和管理网络包的处理规则。iptables 规则会通过 Netfilter 中的“钩子”（hook）插入到网络数据包的处理过程中。

### 3.1 **数据包的处理流程**

当一个数据包到达内核时，它会经过以下的处理流程（以 `iptables` 为例）：

1. **PREROUTING**：数据包进入网络栈时，首先通过 `PREROUTING` 链进行处理，常用于目的地址转换（DNAT）。
2. **Routing Decision**：路由决定阶段，确定数据包的去向（是否转发到其他主机）。
3. **INPUT**：如果数据包的目标是本机，则进入 `INPUT` 链进行处理。
4. **FORWARD**：如果数据包是转发给其他主机的，则进入 `FORWARD` 链进行处理。
5. **OUTPUT**：如果数据包是本机生成的，则进入 `OUTPUT` 链进行处理。
6. **POSTROUTING**：在数据包离开本机时，经过 `POSTROUTING` 链进行处理，常用于源地址转换（SNAT）。

### 3.2 **规则链的匹配**

每个链都包含一组规则，规则会按照顺序进行检查。每条规则由一个条件（例如，源 IP、目标端口等）和一个动作（例如，接受、丢弃、转发等）组成。

- **规则匹配**：数据包与链中的规则进行匹配。
- **动作**：如果数据包匹配某个规则，`iptables` 会执行该规则指定的动作。常见动作包括：
    - **ACCEPT**：允许数据包继续。
    - **DROP**：丢弃数据包，不做任何处理。
    - **REJECT**：拒绝数据包，并返回错误信息。
    - **SNAT**（源地址转换）：修改数据包的源地址。
    - **DNAT**（目标地址转换）：修改数据包的目标地址。
    - **LOG**：记录匹配的日志信息。

### 4. **四表五链的实际应用**

### 4.1 **Filter 表的使用**

最常见的防火墙配置表。用于控制进出本机的数据流。通过设置 `INPUT`、`OUTPUT` 和 `FORWARD` 链来控制数据包的接收和转发。例如：

```bash
bash
复制编辑
# 允许所有进入本机的 SSH 流量
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
# 阻止所有通过本机转发的数据包
iptables -A FORWARD -j DROP

```

### 4.2 **NAT 表的使用**

NAT 表主要用于修改数据包的源或目标地址。常见的用途是做端口转发和 IP 映射。例如：

```bash
bash
复制编辑
# 端口转发：将外部访问 80 端口的流量转发到内网的 8080 端口
iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination 192.168.1.100:8080
# 修改源地址：使本机的所有流量经过 NAT 处理，隐藏内部 IP
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

```

### 4.3 **Mangle 表的使用**

Mangle 表用于修改数据包的某些字段（如 TTL）。这在流量管理和路由优化中非常有用。例如：

```bash
bash
复制编辑
# 修改数据包的 TTL 值
iptables -t mangle -A POSTROUTING -j TTL --ttl-set 64

```

### 4.4 **Raw 表的使用**

Raw 表主要用于配置是否跟踪连接，通常用于在最初的数据包进入路由之前进行一些特殊的处理。例如：

```bash
bash
复制编辑
# 不对指定流量进行连接跟踪
iptables -t raw -A PREROUTING -p tcp --dport 80 -j NOTRACK

```