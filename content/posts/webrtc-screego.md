---
title: "WebRTC screeGo"
date: 2025-07-02T14:25:26Z
draft: false
tags: ["WebRTC", "实时通信", "分布式系统", "系统架构", "数据库", "存储", "网络协议", "网络编程", "Go语言", "云原生", "容器技术", "性能优化", "高并发"]
author: "Aster"
description: "Created: 2025年3月5日 21:24..."
---

# WebRTC  screeGo

Created: 2025年3月5日 21:24
Status: 完成

## 什么是 WebRTC？[#](https://webrtcforthecurious.com/docs/01-what-why-and-how/#what-is-webrtc)

WebRTC 是 Web Real-Time Communication 的缩写，既是 API 又是协议。WebRTC 协议是两个 WebRTC 代理协商双向安全实时通信的一组规则。然后，WebRTC API 允许开发人员使用 WebRTC 协议。WebRTC API 仅指定用于 JavaScript。

HTTP 和 Fetch API 之间的关系也类似。WebRTC 协议为 HTTP，WebRTC API 为 Fetch API。

WebRTC 协议可用于除 JavaScript 以外的其他 API 和语言。您还可以找到 WebRTC 的服务器和特定于域的工具。所有这些实现都使用 WebRTC 协议，以便它们可以相互交互。

WebRTC 协议在 [rtcweb](https://datatracker.ietf.org/wg/rtcweb/documents/) 工作组的 IETF 中维护。WebRTC API 在 W3C 中记录为 [webrtc](https://www.w3.org/TR/webrtc/)。

## WebRTC 协议是其他技术的集合[#](https://webrtcforthecurious.com/docs/01-what-why-and-how/#the-webrtc-protocol-is-a-collection-of-other-technologies)

WebRTC 协议是一个巨大的话题，需要一整本书来解释。但是，首先，我们将其分为四个步骤。

1. 信号
2. 连接
3. 确保
4. 沟通

这些步骤是连续的，这意味着上一步必须 100% 成功，后续步骤才能开始。

关于 WebRTC 的一个奇特事实是，每个步骤实际上都由许多其他协议组成！为了制作 WebRTC，我们将许多现有技术拼接在一起。从这个意义上说，你可以认为 WebRTC 更像是可追溯到 2000 年代初的广为人知的技术的组合和配置，而不是它本身就是一个全新的过程。

这些步骤中的每一个都有专门的章节，但首先从高层次理解它们会很有帮助。由于它们相互依赖，因此在进一步解释每个步骤的目的时会有所帮助。

### 信令：对等体如何在 WebRTC 中找到彼此[#](https://webrtcforthecurious.com/docs/01-what-why-and-how/#signaling-how-peers-find-each-other-in-webrtc)

当 WebRTC 代理启动时，它不知道它将与谁通信，也不知道他们将要通信什么。*Signaling* 步骤解决了这个问题！信令用于引导呼叫，允许两个独立的 WebRTC 代理开始通信。

信令使用一种称为 SDP（会话描述协议）的现有纯文本协议。每个 SDP 消息都由键/值对组成，并包含一个“媒体部分”列表。两个 WebRTC 代理交换的 SDP 包含如下详细信息：

- 可访问代理的 IP 和端口 （候选项）。
- 代理希望发送的音频和视频轨道的数量。
- 每个代理支持的音频和视频编解码器。
- 连接时使用的值 （/）。`uFraguPwd`
- 保护时使用的值（证书指纹）。

需要注意的是，信令通常是“带外”发生的，这意味着应用程序通常不使用 WebRTC 本身来交换信令消息。在发起 WebRTC 连接之前，双方之间需要有另一个通信通道。使用的通道类型不是 WebRTC 关心的问题。任何适合发送消息的架构都可以在连接的对等体之间中继 SDP，许多应用程序将简单地使用其现有的基础设施（例如 REST 端点、WebSocket 连接或身份验证代理）来促进适当客户端之间的 SDP 交易。

### 使用 STUN/TURN 进行连接和 NAT 遍历[#](https://webrtcforthecurious.com/docs/01-what-why-and-how/#connecting-and-nat-traversal-with-stunturn)

一旦两个 WebRTC 代理交换了 SDP，它们就有足够的信息来尝试相互连接。为了实现这种连接，WebRTC 使用了另一种称为 ICE（交互式连接建立）的成熟技术。

ICE 是一种早于 WebRTC 的协议，允许在没有中央服务器的情况下在两个代理之间建立直接连接。这两个代理可能位于同一网络上，也可能位于世界的另一端。

ICE 支持直接连接，但连接过程的真正魔力涉及一个称为“NAT 遍历”的概念和 STUN/TURN 服务器的使用。这两个概念（我们将在后面更深入地探讨）是您与另一个子网中的 ICE 代理通信所需的全部内容。

当两个代理成功建立 ICE 连接后，WebRTC 继续下一步;建立加密传输以在它们之间共享音频、视频和数据。

### 使用 DTLS 和 SRTP 保护传输层[#](https://webrtcforthecurious.com/docs/01-what-why-and-how/#securing-the-transport-layer-with-dtls-and-srtp)

现在我们已经有了双向通信（通过 ICE），我们需要确保我们的通信安全！这是通过另外两个协议完成的，这两个协议也早于 WebRTC;DTLS（数据报传输层安全性）和 SRTP（安全实时传输协议）。第一种协议 DTLS 只是基于 UDP 的 TLS（TLS 是用于保护 HTTPS 通信的加密协议）。第二种协议 SRTP 用于确保 RTP（实时传输协议）数据包的加密。

首先，WebRTC 通过在 ICE 建立的连接上进行 DTLS 握手来连接。与 HTTPS 不同，WebRTC 不对证书使用中央颁发机构。它只是断言通过 DTLS 交换的证书与通过信令共享的指纹匹配。然后，此 DTLS 连接将用于 DataChannel 消息。

接下来，WebRTC 使用使用 SRTP 保护的 RTP 协议进行音频/视频传输。我们通过从协商的 DTLS 会话中提取密钥来初始化 SRTP 会话。

我们将在后面的章节中讨论为什么媒体和数据传输有自己的协议，但现在知道它们是分开处理的就足够了。

现在我们完成了！我们已经成功地建立了双向和安全的通信。如果您的 WebRTC 代理之间有稳定的连接，这就是您所需要的全部复杂性。在下一节中，我们将讨论 WebRTC 如何处理丢包和带宽限制等不幸的现实世界问题。

### 通过 RTP 和 SCTP 与对等体通信[#](https://webrtcforthecurious.com/docs/01-what-why-and-how/#communicating-with-peers-via-rtp-and-sctp)

现在我们已经连接了两个 WebRTC 代理并建立了安全的双向通信，让我们开始通信吧！同样，WebRTC 将使用两个预先存在的协议：RTP（实时传输协议）和 SCTP（流控制传输协议）。我们使用 RTP 来交换使用 SRTP 加密的媒体，我们使用 SCTP 发送和接收使用 DTLS 加密的 DataChannel 消息。

RTP 是一个相当小的协议，但它提供了实现实时流式处理的必要工具。RTP 最重要的一点是它为开发人员提供了灵活性，使他们能够随心所欲地处理延迟、包丢失和拥塞。我们将在媒体章节中进一步讨论这个问题。

堆栈中的最后一个协议是 SCTP。SCTP 的重要一点是，您可以关闭 Reliable and order 消息传递（在许多不同的选项中）。这使开发人员能够确保实时系统所需的延迟。

## WebRTC，协议集合[#](https://webrtcforthecurious.com/docs/01-what-why-and-how/#webrtc-a-collection-of-protocols)

WebRTC 解决了很多问题。乍一看，这项技术似乎过于设计化，但 WebRTC 的天才之处在于它的谦逊。它不是在假设它可以更好地解决所有问题的假设下创建的。相反，它采用了许多现有的单一用途技术，并将它们整合到一个简化的、广泛适用的捆绑包中。

这使我们能够单独检查和学习每个部分，而不会不知所措。一个可视化的好方法是“WebRTC 代理”实际上只是许多不同协议的编排器。

![image.png](WebRTC%20screeGo%201ad4bf1cd99880d6bd07e0255b5b7dfe/image.png)

## WebRTC API 是如何工作的？[#](https://webrtcforthecurious.com/docs/01-what-why-and-how/#how-does-the-webrtc-api-work)

本节概述了 WebRTC JavaScript API 如何映射到上述 WebRTC 协议。它并不是作为 WebRTC API 的广泛演示，而是为了创建一个关于一切如何联系在一起的心智模型。

### `new RTCPeerConnection` [#](https://webrtcforthecurious.com/docs/01-what-why-and-how/#new-rtcpeerconnection)

这是顶级的 “WebRTC Session”。它包含上述所有协议。子系统都已分配，但尚未发生任何事情。`RTCPeerConnection`

### `addTrack` [#](https://webrtcforthecurious.com/docs/01-what-why-and-how/#addtrack)

`addTrack`创建新的 RTP 流。将为此流生成随机同步源 （SSRC）。然后，此流将位于 Inside a media 部分生成的 Session Description 中。每次调用都将创建一个新的 SSRC 和媒体部分。`createOfferaddTrack`

建立 SRTP 会话后，这些媒体数据包将立即开始使用 SRTP 加密并通过 ICE 发送。

### `createDataChannel` [#](https://webrtcforthecurious.com/docs/01-what-why-and-how/#createdatachannel)

`createDataChannel`如果不存在 SCTP 关联，则创建新的 SCTP 流。默认情况下，SCTP 未启用。仅当一方请求 data 通道时，它才会启动。

建立 DTLS 会话后，SCTP 关联将立即开始通过 ICE 发送使用 DTLS 加密的数据包。

### `createOffer` [#](https://webrtcforthecurious.com/docs/01-what-why-and-how/#createoffer)

`createOffer`生成要与远程对等体共享的本地状态的 Session Description。

调用作不会更改本地 Peer 节点的任何内容。`createOffer`

### `setLocalDescription` [#](https://webrtcforthecurious.com/docs/01-what-why-and-how/#setlocaldescription)

`setLocalDescription`提交任何请求的更改。在此调用之前，调用 、 和类似调用是临时的。 使用 生成的值调用 。`addTrackcreateDataChannelsetLocalDescriptioncreateOffer`

通常，在此调用之后，您会将选件发送给远程对等体，远程对等体将使用它来调用 。`setRemoteDescription`

### `setRemoteDescription` [#](https://webrtcforthecurious.com/docs/01-what-why-and-how/#setremotedescription)

`setRemoteDescription`是我们向本地代理通知远程候选人状态的方式。这就是使用 JavaScript API 完成 'Signaling'作的方式。

当双方都被调用时，WebRTC 代理现在有足够的信息来开始进行点对点 （P2P） 通信！`setRemoteDescription`

### `addIceCandidate` [#](https://webrtcforthecurious.com/docs/01-what-why-and-how/#addicecandidate)

`addIceCandidate`允许 WebRTC 代理随时添加更多远程 ICE 候选项。此 API 将 ICE 候选者直接发送到 ICE 子系统中，并且对更大的 WebRTC 连接没有其他影响。

### `ontrack` [#](https://webrtcforthecurious.com/docs/01-what-why-and-how/#ontrack)

`ontrack`是从远程对等体收到 RTP 数据包时触发的回调。传入的数据包将在传递给 的会话描述中声明。`setRemoteDescription`

WebRTC 使用 SSRC 并查找关联的 和 ，并在填充这些详细信息的情况下触发此回调。`MediaStreamMediaStreamTrack`

### `oniceconnectionstatechange` [#](https://webrtcforthecurious.com/docs/01-what-why-and-how/#oniceconnectionstatechange)

`oniceconnectionstatechange`是触发的回调，它反映了 ICE 代理状态的变化。当您的网络连接发生变化时，这就是您的通知方式。

### `onconnectionstatechange` [#](https://webrtcforthecurious.com/docs/01-what-why-and-how/#onconnectionstatechange)

`onconnectionstatechange`是 ICE 代理和 DTLS 代理状态的组合。您可以观看此视频，以便在 ICE 和 DTLS 都成功完成时收到通知。

# 信号[#](https://webrtcforthecurious.com/docs/02-signaling/#signaling)

## 什么是 WebRTC 信令？[#](https://webrtcforthecurious.com/docs/02-signaling/#what-is-webrtc-signaling)

当您创建 WebRTC 代理时，它对另一个对等体一无所知。它不知道它将与谁连接或他们将发送什么！ 信令是使呼叫成为可能的初始引导。交换这些值后，WebRTC 代理可以直接相互通信。

信令消息只是文本。WebRTC 代理并不关心它们是如何传输的。它们通常通过 Websockets 共享，但这不是必需的。

## WebRTC 信令如何工作？[#](https://webrtcforthecurious.com/docs/02-signaling/#how-does-webrtc-signaling-work)

WebRTC 使用称为会话描述协议的现有协议。通过此协议，两个 WebRTC 代理将共享建立连接所需的所有状态。协议本身易于阅读和理解。 复杂性来自于理解 WebRTC 填充它的所有值。

此协议并非特定于 WebRTC。我们将首先学习会话描述协议，甚至不谈论 WebRTC。WebRTC 只真正利用了协议的一个子集，因此我们只将涵盖我们需要的内容。 了解协议后，我们将继续讨论它在 WebRTC 中的应用。

## 什么是*会话描述协议* （SDP）？[#](https://webrtcforthecurious.com/docs/02-signaling/#what-is-the-session-description-protocol-sdp)

会话描述协议在 [RFC 8866](https://tools.ietf.org/html/rfc8866) 中定义。它是一个键/值协议，每个值后都有一个换行符。它感觉类似于 INI 文件。 会话描述包含零个或多个媒体描述。在脑海中，你可以将其建模为包含一系列 Media Descriptions 的 Session Description。

媒体描述通常映射到单个媒体流。因此，如果要描述具有三个视频流和两个音频轨道的呼叫，您将有五个媒体描述。

### 如何阅读 SDP[#](https://webrtcforthecurious.com/docs/02-signaling/#how-to-read-the-sdp)

Session Description 中的每一行都将以一个字符开头，这是您的键。然后，它后面会跟一个等号。该等号之后的所有内容都是值。值完成后，您将有一个换行符。

会话描述协议定义所有有效的密钥。您只能对协议中定义的键使用字母。这些键都有重要的含义，后面会解释。

请摘录此会议描述：

```
a=my-sdp-value
a=second-value

```

你有两条线。每个都带有键 。第一行的值为 ，第二行的值为 。`amy-sdp-valuesecond-value`

### WebRTC 仅使用部分 SDP 密钥[#](https://webrtcforthecurious.com/docs/02-signaling/#webrtc-only-uses-some-sdp-keys)

并非 WebRTC 使用会话描述协议定义的所有键值。只有 [RFC 8829](https://datatracker.ietf.org/doc/html/rfc8829) 中定义的 JavaScript 会话建立协议 （JSEP） 中使用的密钥才重要。以下七个关键是您现在唯一需要了解的关键：

- `v0`
    - Version 应等于 。
- `o`
    - 来源，包含对重新协商有用的唯一 ID。
- `s`
    - 会话名称 应等于 。
- `t0 0`
    - Timing，应等于 。
- `mm=<media> <port> <proto> <fmt> ...`
    - 媒体描述 （），详见下文。
- `a`
    - Attribute，自由文本字段。这是 WebRTC 中最常见的行。
- `cIN IP4 0.0.0.0`
    - 连接数据 应等于 。

### 会话描述中的媒体描述[#](https://webrtcforthecurious.com/docs/02-signaling/#media-descriptions-in-a-session-description)

会话描述可以包含无限数量的媒体描述。

Media Description 定义包含格式列表。这些格式映射到 RTP 负载类型。然后，实际的编解码器由 Attribute 定义，其值位于 Media Description 中。 RTP 和 RTP Payload Types 的重要性将在 Media 一章的后面讨论。每个媒体描述可以包含无限数量的属性。`rtpmap`

以此 Session Description 摘录为例：

```
v=0
m=audio 4000 RTP/AVP 111
a=rtpmap:111 OPUS/48000/2
m=video 4000 RTP/AVP 96
a=rtpmap:96 VP8/90000
a=my-sdp-value

```

您有两个媒体描述，一个是带有 fmt 的音频类型，另一个是格式为 的视频 .第一个 Media Description 只有一个属性。此属性将 Payload Type 映射到 Opus。 第二个 Media Description 有两个属性。第一个属性将 Payload Type 映射为 VP8，第二个属性只是 .`1119611196my-sdp-value`

### 完整示例[#](https://webrtcforthecurious.com/docs/02-signaling/#full-example)

下面将我们讨论过的所有概念放在一起。这些是 WebRTC 使用的会话描述协议的所有功能。 如果你能读懂这篇文章，你就可以读到任何 WebRTC 会话描述！

```
v=0
o=- 0 0 IN IP4 127.0.0.1
s=-
c=IN IP4 127.0.0.1
t=0 0
m=audio 4000 RTP/AVP 111
a=rtpmap:111 OPUS/48000/2
m=video 4002 RTP/AVP 96
a=rtpmap:96 VP8/90000

```

- `vosct`
    
    、 ，但它们不会影响 WebRTC 会话。
    
- 您有两个 Media Description。一个是 type 和一个 type 。`audiovideo`
- 它们中的每一个都有一个属性。此属性配置 RTP 管道的详细信息，这在 “媒体通信” 一章中讨论。

## *会话描述协议*和 WebRTC 如何协同工作[#](https://webrtcforthecurious.com/docs/02-signaling/#how-session-description-protocol-and-webrtc-work-together)

下一个难题是了解 WebRTC *如何使用* Session Description Protocol。

### 什么是选件和答案？[#](https://webrtcforthecurious.com/docs/02-signaling/#what-are-offers-and-answers)

WebRTC 使用选件/答案模型。所有这一切都意味着，一个 WebRTC 代理发出 “要约” 来开始通话，而其他 WebRTC 代理 如果愿意接受所提供的 “回答”。

这使应答者有机会在 Media Descriptions 中拒绝不支持的编解码器。这就是两个对等方如何了解他们愿意交换哪些格式。

### 收发器用于发送和接收[#](https://webrtcforthecurious.com/docs/02-signaling/#transceivers-are-for-sending-and-receiving)

收发器是您将在 API 中看到的 WebRTC 特定概念。它所做的是将 “Media Description” 暴露给 JavaScript API。每个 Media Description 都成为一个收发器。 每次创建 Transceiver 时，都会将新的 Media Description 添加到本地 Session Description。

WebRTC 中的每个媒体描述都将具有一个 direction 属性。这允许 WebRTC 代理声明“我将向您发送此编解码器，但我不愿意接受任何返回”。有四个有效值：

- `send`
- `recv`
- `sendrecv`
- `inactive`

### WebRTC 使用的 SDP 值[#](https://webrtcforthecurious.com/docs/02-signaling/#sdp-values-used-by-webrtc)

这是您将在 WebRTC 代理的会话描述中看到的一些常见属性的列表。其中许多值控制我们尚未讨论的子系统。

### `group:BUNDLE` [#](https://webrtcforthecurious.com/docs/02-signaling/#groupbundle)

捆绑是指在一个连接上运行多种类型的流量的行为。某些 WebRTC 实现对每个媒体流使用专用连接。应首选捆绑销售。

### `fingerprint:sha-256` [#](https://webrtcforthecurious.com/docs/02-signaling/#fingerprintsha-256)

这是对等体用于 DTLS 的证书的哈希值。DTLS 握手完成后，您将其与实际证书进行比较，以确认您正在与预期的人进行通信。

### `setup:` [#](https://webrtcforthecurious.com/docs/02-signaling/#setup)

这将控制 DTLS 代理 的行为。这决定了它在 ICE 连接后是作为客户端还是服务器运行。可能的值为：

- `setup:active`
    - 作为 DTLS 客户端运行。
- `setup:passive`
    - 作为 DTLS 服务器运行。
- `setup:actpass`
    - 让其他 WebRTC 代理进行选择。

### `mid` [#](https://webrtcforthecurious.com/docs/02-signaling/#mid)

“mid” 属性用于标识会话描述中的媒体流。

### `ice-ufrag` [#](https://webrtcforthecurious.com/docs/02-signaling/#ice-ufrag)

这是 ICE 代理的用户片段值。用于 ICE 流量的身份验证。

### `ice-pwd` [#](https://webrtcforthecurious.com/docs/02-signaling/#ice-pwd)

这是 ICE 代理的密码。用于 ICE 流量的身份验证。

### `rtpmap` [#](https://webrtcforthecurious.com/docs/02-signaling/#rtpmap)

此值用于将特定编解码器映射到 RTP 负载类型。有效负载类型不是静态的，因此对于每次调用，提供方都会决定每个编解码器的有效负载类型。

### `fmtp` [#](https://webrtcforthecurious.com/docs/02-signaling/#fmtp)

定义一个 Payload Type 的附加值。这对于传达特定的视频配置文件或编码器设置非常有用。

### `candidate` [#](https://webrtcforthecurious.com/docs/02-signaling/#candidate)

这是来自 ICE 代理的 ICE 候选者。这是 WebRTC 代理可用的一个可能地址。这些将在下一章中详细解释。

### `ssrc` [#](https://webrtcforthecurious.com/docs/02-signaling/#ssrc)

同步源 （SSRC） 定义单个媒体流轨道。

`label`是此单个流的 ID。 是容器中可以包含多个流的容器的 ID。`mslabel`

### WebRTC 会话描述示例[#](https://webrtcforthecurious.com/docs/02-signaling/#example-of-a-webrtc-session-description)

以下是 WebRTC 客户端生成的完整 Session 描述：

```
v=0
o=- 3546004397921447048 1596742744 IN IP4 0.0.0.0
s=-
t=0 0
a=fingerprint:sha-256 0F:74:31:25:CB:A2:13:EC:28:6F:6D:2C:61:FF:5D:C2:BC:B9:DB:3D:98:14:8D:1A:BB:EA:33:0C:A4:60:A8:8E
a=group:BUNDLE 0 1
m=audio 9 UDP/TLS/RTP/SAVPF 111
c=IN IP4 0.0.0.0
a=setup:active
a=mid:0
a=ice-ufrag:CsxzEWmoKpJyscFj
a=ice-pwd:mktpbhgREmjEwUFSIJyPINPUhgDqJlSd
a=rtcp-mux
a=rtcp-rsize
a=rtpmap:111 opus/48000/2
a=fmtp:111 minptime=10;useinbandfec=1
a=ssrc:350842737 cname:yvKPspsHcYcwGFTw
a=ssrc:350842737 msid:yvKPspsHcYcwGFTw DfQnKjQQuwceLFdV
a=ssrc:350842737 mslabel:yvKPspsHcYcwGFTw
a=ssrc:350842737 label:DfQnKjQQuwceLFdV
a=msid:yvKPspsHcYcwGFTw DfQnKjQQuwceLFdV
a=sendrecv
a=candidate:foundation 1 udp 2130706431 192.168.1.1 53165 typ host generation 0
a=candidate:foundation 2 udp 2130706431 192.168.1.1 53165 typ host generation 0
a=candidate:foundation 1 udp 1694498815 1.2.3.4 57336 typ srflx raddr 0.0.0.0 rport 57336 generation 0
a=candidate:foundation 2 udp 1694498815 1.2.3.4 57336 typ srflx raddr 0.0.0.0 rport 57336 generation 0
a=end-of-candidates
m=video 9 UDP/TLS/RTP/SAVPF 96
c=IN IP4 0.0.0.0
a=setup:active
a=mid:1
a=ice-ufrag:CsxzEWmoKpJyscFj
a=ice-pwd:mktpbhgREmjEwUFSIJyPINPUhgDqJlSd
a=rtcp-mux
a=rtcp-rsize
a=rtpmap:96 VP8/90000
a=ssrc:2180035812 cname:XHbOTNRFnLtesHwJ
a=ssrc:2180035812 msid:XHbOTNRFnLtesHwJ JgtwEhBWNEiOnhuW
a=ssrc:2180035812 mslabel:XHbOTNRFnLtesHwJ
a=ssrc:2180035812 label:JgtwEhBWNEiOnhuW
a=msid:XHbOTNRFnLtesHwJ JgtwEhBWNEiOnhuW
a=sendrecv

```

以下是我们从这条消息中了解到的信息：

- 我们有两个媒体部分，一个音频部分和一个视频部分。
- 它们都是收发器。我们得到了两个流，我们可以发回两个。`sendrecv`
- 我们有 ICE 候选项和身份验证详细信息，因此我们可以尝试连接。
- 我们有证书指纹，因此我们可以进行安全调用。

# 连接[#](https://webrtcforthecurious.com/docs/03-connecting/#connecting)

## 为什么 WebRTC 需要一个专用的子系统进行连接？[#](https://webrtcforthecurious.com/docs/03-connecting/#why-does-webrtc-need-a-dedicated-subsystem-for-connecting)

目前部署的大多数应用程序都会建立客户端/服务器连接。客户端/服务器连接要求服务器具有稳定的已知传输地址。客户端联系服务器，服务器响应。

WebRTC 不使用客户端/服务器模型，它建立点对点 （P2P） 连接。在 P2P 连接中，创建连接的任务平均分配给两个对等体。这是因为 WebRTC 中的传输地址（IP 和端口）无法假设，甚至可能在会话期间发生变化。WebRTC 将收集它所能收集的所有信息，并将不遗余力地实现两个 WebRTC 代理之间的双向通信。

但是，建立点对点连接可能很困难。这些代理可能位于不同的网络中，没有直接连接。在存在直接连接的情况下，您仍可能会遇到其他问题。在某些情况下，您的客户端不使用相同的网络协议（UDP <-> TCP），或者可能使用不同的 IP 版本（IPv4 <-> IPv6）。

尽管在设置 P2P 连接方面存在这些困难，但由于 WebRTC 提供的以下属性，您可以获得优于传统客户端/服务器技术的优势。

### 降低带宽成本[#](https://webrtcforthecurious.com/docs/03-connecting/#reduced-bandwidth-costs)

由于媒体通信直接在对等方之间进行，因此您不必付费，也无需托管单独的服务器来中继媒体。

### 更低的延迟[#](https://webrtcforthecurious.com/docs/03-connecting/#lower-latency)

直接沟通时更快！当用户必须通过您的服务器运行所有内容时，它会使传输速度变慢。

### 安全的 E2E 通信[#](https://webrtcforthecurious.com/docs/03-connecting/#secure-e2e-communication)

直接通信更安全。由于用户没有通过您的服务器路由数据，因此他们甚至不需要相信您不会解密数据。

## 它是如何工作的？[#](https://webrtcforthecurious.com/docs/03-connecting/#how-does-it-work)

上述过程称为交互式连接建立 （[ICE](https://tools.ietf.org/html/rfc8445)）。另一个早于 WebRTC 的协议。

ICE 是一种协议，它试图找到在两个 ICE 代理之间通信的最佳方式。每个 ICE 代理都会发布其可访问的方式，这些方式称为候选项。候选者本质上是它认为其他对等体可以访问的代理的传输地址。然后，ICE 会确定最佳候选人配对。

本章后面将更详细地介绍实际的 ICE 过程。要了解 ICE 存在的原因，了解我们正在克服的网络行为是很有用的。

## 网络实际约束[#](https://webrtcforthecurious.com/docs/03-connecting/#networking-real-world-constraints)

ICE 旨在克服现实世界网络的限制。在我们探索解决方案之前，我们先谈谈实际问题。

### 不在同一网络中[#](https://webrtcforthecurious.com/docs/03-connecting/#not-in-the-same-network)

大多数情况下，另一个 WebRTC 代理甚至不会在同一个网络中。典型的呼叫通常是在不同网络中的两个 WebRTC 代理之间，没有直接连接。

下图是两个不同网络的图表，它们通过公共 Internet 连接。在每个网络中，您有两台主机。

![](https://webrtcforthecurious.com/docs/images/03-two-networks.png)

对于同一网络中的主机，连接非常容易。之间的通信很容易做到！这两台主机可以在没有任何外部帮助的情况下相互连接。`192.168.0.1 -> 192.168.0.2`

但是，使用 的主机无法直接访问后面的任何内容。您如何区分 behind 和 behind 的同一 IP ？它们是私有 IP！使用的主机可以直接将流量发送到 ，但请求将在此处结束。如何知道应该将邮件转发到哪个主机？`Router BRouter A192.168.0.1Router ARouter BRouter BRouter ARouter A`

### 协议限制[#](https://webrtcforthecurious.com/docs/03-connecting/#protocol-restrictions)

某些网络根本不允许 UDP 流量，或者它们可能不允许 TCP。某些网络可能具有非常低的 MTU （最大传输单位）。网络管理员可以更改许多变量，这些变量可能会使通信变得困难。

### 防火墙/IDS 规则[#](https://webrtcforthecurious.com/docs/03-connecting/#firewallids-rules)

另一种是“深度数据包检测”和其他智能过滤。一些网络管理员将运行尝试处理每个数据包的软件。很多时候这个软件不理解 WebRTC，所以它阻止它，因为它不知道该怎么做，例如将 WebRTC 数据包视为未列入白名单的任意端口上的可疑 UDP 数据包。

## NAT 映射[#](https://webrtcforthecurious.com/docs/03-connecting/#nat-mapping)

NAT（网络地址转换）映射是使 WebRTC 连接成为可能的魔力。这就是 WebRTC 允许完全不同子网中的两个对等体进行通信的方式，解决了上述“不在同一网络中”的问题。虽然它带来了新的挑战，但让我们首先解释一下 NAT 映射的工作原理。

它不使用中继、代理或服务器。同样，我们有 和 ，它们位于不同的网络中。但是，流量完全流经。可视化后，它看起来像这样：`Agent 1Agent 2`

![](https://webrtcforthecurious.com/docs/images/03-nat-mapping.png)

要进行此通信，您需要建立 NAT 映射。Agent 1 使用端口 7000 与 Agent 2 建立 WebRTC 连接。这将创建 到 的绑定。然后，这允许代理 2 通过向 发送数据包来到达代理 1。创建本示例中的 NAT 映射类似于在路由器中执行端口转发的自动化版本。`192.168.0.1:70005.0.0.1:70005.0.0.1:7000`

NAT 映射的缺点是没有单一形式的映射（例如静态端口转发），并且网络之间的行为不一致。ISP 和硬件制造商可能以不同的方式执行此作。在某些情况下，网络管理员甚至可能会禁用它。

好消息是，所有的行为都是可以理解和观察的，因此 ICE 代理能够确认它创建了 NAT 映射以及映射的属性。

描述这些行为的文档是 [RFC 4787](https://tools.ietf.org/html/rfc4787)。

### 创建映射[#](https://webrtcforthecurious.com/docs/03-connecting/#creating-a-mapping)

创建映射是最简单的部分。当您将数据包发送到网络外部的地址时，将创建一个映射！NAT 映射只是由 NAT 分配的临时公有 IP 和端口。出站邮件将被重写，使其源地址由新映射地址提供。如果将消息发送到映射，它将自动路由回创建该消息的 NAT 内的主机。映射的细节是它变得复杂的地方。

### 映射创建行为[#](https://webrtcforthecurious.com/docs/03-connecting/#mapping-creation-behaviors)

映射创建分为三个不同的类别：

### 独立于端点的映射[#](https://webrtcforthecurious.com/docs/03-connecting/#endpoint-independent-mapping)

将为 NAT 中的每个发件人创建一个映射。如果您将两个数据包发送到两个不同的远程地址，则将重复使用 NAT 映射。两个远程主机将看到相同的源 IP 和端口。如果远程主机响应，则会将其发送回同一本地侦听器。

这是最好的情况。要使调用正常工作，至少有一端是此类型。

### 地址相关映射[#](https://webrtcforthecurious.com/docs/03-connecting/#address-dependent-mapping)

每次将数据包发送到新地址时，都会创建一个新的映射。如果您将两个数据包发送到不同的主机，将创建两个映射。如果将两个数据包发送到同一远程主机但目标端口不同，则不会创建新映射。

### 地址和端口相关映射[#](https://webrtcforthecurious.com/docs/03-connecting/#address-and-port-dependent-mapping)

如果远程 IP 或端口不同，则会创建一个新映射。如果将两个数据包发送到同一远程主机，但目标端口不同，则将创建一个新映射。

### 映射筛选行为[#](https://webrtcforthecurious.com/docs/03-connecting/#mapping-filtering-behaviors)

映射筛选是有关允许谁使用映射的规则。它们分为三个类似的分类：

### 独立于端点的筛选[#](https://webrtcforthecurious.com/docs/03-connecting/#endpoint-independent-filtering)

任何人都可以使用映射。您可以与其他多个对等体共享映射，它们都可以向其发送流量。

### Address Dependent 筛选[#](https://webrtcforthecurious.com/docs/03-connecting/#address-dependent-filtering)

只有为其创建映射的主机才能使用映射。如果向 host 发送数据包，则只能从同一主机获得响应。如果 host 尝试将数据包发送到该映射，则将被忽略。`AB`

### 地址和端口相关筛选[#](https://webrtcforthecurious.com/docs/03-connecting/#address-and-port-dependent-filtering)

只有为其创建映射的主机和端口才能使用该映射。如果将数据包发送到 ，则只能从同一主机和端口获得响应。如果尝试将数据包发送到该映射，则将被忽略。`A:5000A:5001`

### 映射刷新[#](https://webrtcforthecurious.com/docs/03-connecting/#mapping-refresh)

建议如果映射在 5 分钟内未使用，则应将其销毁。这完全取决于 ISP 或硬件制造商。

## STUN[#](https://webrtcforthecurious.com/docs/03-connecting/#stun)

STUN （Session Traversal Utilities for NAT） 是一种专为使用 NAT 而创建的协议。这是早于 WebRTC（和 ICE）的另一项技术。它由 [RFC 8489 定义，RFC 8489](https://tools.ietf.org/html/rfc8489) 还定义了 STUN 数据包结构。STUN 协议也被 ICE/TURN 使用。

STUN 非常有用，因为它允许以编程方式创建 NAT 映射。在 STUN 之前，我们能够创建 NAT 映射，但我们不知道它的 IP 和端口是什么！STUN 不仅使您能够创建映射，还为您提供详细信息，以便您可以与他人共享它们，以便他们可以通过您刚刚创建的映射将流量发送回给您。

让我们从 STUN 的基本描述开始。稍后，我们将扩展 TURN 和 ICE 的使用。现在，我们只介绍用于创建映射的 Request/Response 流。然后我们将讨论如何获取它的详细信息以与他人共享。当您的 ICE URL 中有 WebRTC PeerConnection 的服务器时，就会发生此过程。简而言之，STUN 通过要求 NAT 外部的 STUN 服务器报告它观察到的内容，帮助 NAT 后面的终端节点找出创建的映射。`stun:`

### 协议结构[#](https://webrtcforthecurious.com/docs/03-connecting/#protocol-structure)

每个 STUN 数据包具有以下结构：

```
 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|0 0|     STUN Message Type     |         Message Length        |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                         Magic Cookie                          |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                                                               |
|                     Transaction ID (96 bits)                  |
|                                                               |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                             Data                              |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

```

### STUN 消息类型[#](https://webrtcforthecurious.com/docs/03-connecting/#stun-message-type)

每个 STUN 数据包都有一个类型。目前，我们只关心以下内容：

- 绑定请求 -`0x0001`
- 绑定响应 -`0x0101`

要创建 NAT 映射，我们创建一个 .然后，服务器以 .`Binding RequestBinding Response`

### 消息长度[#](https://webrtcforthecurious.com/docs/03-connecting/#message-length)

这是该部分的长度。此部分包含由 .`DataMessage Type`

### 魔法饼干[#](https://webrtcforthecurious.com/docs/03-connecting/#magic-cookie)

网络字节顺序的固定值，有助于区分 STUN 流量和其他协议。`0x2112A442`

### 交易 ID[#](https://webrtcforthecurious.com/docs/03-connecting/#transaction-id)

唯一标识请求/响应的 96 位标识符。这有助于您将请求和响应配对。

### 数据[#](https://webrtcforthecurious.com/docs/03-connecting/#data)

数据将包含 STUN 属性列表。STUN 属性具有以下结构：

```
0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|         Type                  |            Length             |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                         Value (variable)                ....
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

```

这 不使用任何属性。这意味着 a 仅包含标头。`STUN Binding RequestSTUN Binding Request`

使用 .此属性包含 IP 和端口。这是创建的 NAT 映射的 IP 和端口！`STUN Binding ResponseXOR-MAPPED-ADDRESS (0x0020)`

### 创建 NAT 映射[#](https://webrtcforthecurious.com/docs/03-connecting/#create-a-nat-mapping)

使用 STUN 创建 NAT 映射只需发送一个请求！您将 发送到 STUN 服务器。然后，STUN 服务器以 . 这将包含 .这就是 STUN 服务器看到您的方式，也是您的 . 如果您希望有人向您发送数据包，这就是您将共享的内容。`STUN Binding RequestSTUN Binding ResponseSTUN Binding ResponseMapped AddressMapped AddressNAT mappingMapped Address`

人们也会称 ur 或 .`Mapped AddressPublic IPServer Reflexive Candidate`

### 确定 NAT 类型[#](https://webrtcforthecurious.com/docs/03-connecting/#determining-nat-type)

不幸的是，这可能并非在所有情况下都有用。如果是，则只有 STUN 服务器可以将流量发送回给您。如果您共享了该消息，并且其他对等方尝试发送消息，则它们将被丢弃。这使得它对与他人交流毫无用处。你可能会发现这个案子实际上是可以解决的，如果运行 STUN 服务器的主机也可以为你转发数据包到对等体！这让我们想到了下面使用 TURN 的解决方案。`Mapped AddressAddress DependentAddress Dependent`

[RFC 5780](https://tools.ietf.org/html/rfc5780) 定义了一种运行测试以确定 NAT 类型的方法。这很有用，因为您可以提前知道是否可以直接连接。

## TURN[#](https://webrtcforthecurious.com/docs/03-connecting/#turn)

TURN （Traversal Using Relays around NAT） 在 [RFC 8656](https://tools.ietf.org/html/rfc8656) 中定义，是无法直接连接时的解决方案。这可能是因为您有两个不兼容的 NAT 类型，或者可能无法使用相同的协议！TURN 也可用于隐私目的。通过 TURN 运行所有通信，您可以隐藏客户端的实际地址。

TURN 使用专用服务器。此服务器充当客户端的代理。客户端连接到 TURN 服务器并创建一个 .通过创建分配，客户端将获得一个临时 IP/端口/协议，该 IP/端口/协议可用于将流量发送回客户端。这个新的侦听器称为 .把它想象成一个转发地址，你把它给出来，这样其他人就可以通过 TURN 给你发送流量了！对于您授予 to 的每个 peer 节点，您必须创建一个新的 view 以允许与您通信。`AllocationRelayed Transport AddressRelay Transport AddressPermission`

当您通过 TURN 发送出站流量时，它将通过 .当远程对等体获得流量时，他们会看到来自 TURN 服务器的流量。`Relayed Transport Address`

### TURN 生命周期[#](https://webrtcforthecurious.com/docs/03-connecting/#turn-lifecycle)

以下是希望创建 TURN 分配的客户端必须执行的所有作。与使用 TURN 的用户通信不需要任何更改。另一个对等体获得 IP 和端口，并且它们像任何其他主机一样与之通信。

### 分配[#](https://webrtcforthecurious.com/docs/03-connecting/#allocations)

分配是 TURN 的核心。An 基本上是一个 “TURN Session”。要创建 TURN 分配，请与 TURN（通常是 port ）通信。`allocationServer Transport Address3478`

创建分配时，您需要提供以下内容：

- 用户名/密码 - 创建 TURN 分配需要身份验证。
- 分配传输 - 服务器 （） 与对等体之间的传输协议，可以是 UDP 或 TCP。`Relayed Transport Address`
- 偶数端口 - 您可以为多个分配请求顺序端口，这与 WebRTC 无关。

如果请求成功，您将在 Data （数据） 部分收到 TURN 服务器的响应，其中包含以下 STUN 属性：

- `XOR-MAPPED-ADDRESS` - `Mapped AddressTURN ClientRelayed Transport Address`
    
    的 .当有人将数据发送到 this 时，数据将被转发到。
    
- `RELAYED-ADDRESS`
    - 这是您提供给其他客户的地址。如果有人向此地址发送数据包，则会将其中继到 TURN 客户端。
- `LIFETIMERefresh`
    - 此 TURN 分配被销毁之前多长时间。您可以通过发送请求来延长生命周期。

### 权限[#](https://webrtcforthecurious.com/docs/03-connecting/#permissions)

远程主机在您为其创建权限之前无法发送到您的主机。当您创建权限时，您告诉 TURN 服务器允许此 IP 和端口发送入站流量。`Relayed Transport Address`

远程主机需要为您提供 TURN 服务器显示的 IP 和端口。这意味着它应该向 TURN 服务器发送 。一个常见的错误情况是远程主机将 发送到不同的服务器。然后他们会要求您为此 IP 创建权限。`STUN Binding RequestSTUN Binding Request`

假设您要为 .如果您从其他 TURN 服务器生成 ，则所有入站流量都将被丢弃。每次它们与不同的主机通信时，它都会生成一个新的映射。如果未刷新，则权限将在 5 分钟后过期。`Address Dependent MappingMapped Address`

### SendIndication/ChannelData[#](https://webrtcforthecurious.com/docs/03-connecting/#sendindicationchanneldata)

这两条消息供 TURN 客户端向远程对等体发送消息。

SendIndication 是一条自包含的消息。它里面是你想要发送的数据，以及你希望发送给谁。如果要向远程对等节点发送大量消息，则这是浪费。如果您发送 1,000 封邮件，您将重复他们的 IP 地址 1,000 次！

ChannelData 允许您发送数据，但不能重复 IP 地址。您可以创建一个具有 IP 和端口的 Channel。然后，您使用 ChannelId 发送，IP 和端口将在服务器端填充。如果您要发送大量消息，这是更好的选择。

### 刷新[#](https://webrtcforthecurious.com/docs/03-connecting/#refreshing)

分配会自动销毁自身。在创建分配时，TURN 客户端必须比给定的时间早刷新它们。`LIFETIME`

### TURN 用法[#](https://webrtcforthecurious.com/docs/03-connecting/#turn-usage)

TURN 用法有两种形式。通常，您的一个对等体充当“TURN 客户端”，另一端直接通信。在某些情况下，您可能在两端都使用 TURN，例如，因为两个客户端都位于阻止 UDP 的网络中，因此与相应 TURN 服务器的连接是通过 TCP 进行的。

这些图表有助于说明这将是什么样子。

### 用于通信的 One TURN 分配[#](https://webrtcforthecurious.com/docs/03-connecting/#one-turn-allocation-for-communication)

![](https://webrtcforthecurious.com/docs/images/03-one-turn-allocation.png)

### 两个用于通信的 TURN 分配[#](https://webrtcforthecurious.com/docs/03-connecting/#two-turn-allocations-for-communication)

![](https://webrtcforthecurious.com/docs/images/03-two-turn-allocations.png)

## ICE[#](https://webrtcforthecurious.com/docs/03-connecting/#ice)

ICE（交互式连接建立）是 WebRTC 连接两个代理的方式。在 [RFC 8445](https://tools.ietf.org/html/rfc8445) 中定义，这是另一项早于 WebRTC 的技术！ICE 是一种用于建立连接的协议。它确定两个对等体之间所有可能的路由，然后确保您保持连接。

这些路由称为 ，它是本地和远程传输地址的对。这就是 STUN 和 TURN 与 ICE 一起发挥作用的地方。这些地址可以是您的本地 IP 地址加上端口、 或 .每一方都收集了他们想用的所有地址，交换它们，然后尝试连接！`Candidate PairsNAT mappingRelayed Transport Address`

两个 ICE 代理使用 ICE ping 数据包（或正式名称为连接检查）进行通信以建立连接。建立连接后，他们可以发送所需的任何数据。这就像使用普通的套接字一样。这些检查使用 STUN 协议。

### 创建 ICE 代理[#](https://webrtcforthecurious.com/docs/03-connecting/#creating-an-ice-agent)

ICE 代理是 或 。代理是决定所选 .通常，发送 offer 的 peer 节点是控制方。`ControllingControlledControllingCandidate Pair`

每侧都必须有 a 和 a 。在连接检查开始之前，必须交换这两个值。它以纯文本形式发送，可用于对多个 ICE 会话进行解复用。 用于生成属性。在每个 STUN 数据包的末尾，都有一个属性，该属性是使用 as 键的整个数据包的哈希值。这用于验证数据包并确保它未被篡改。`user fragmentpassworduser fragmentpasswordMESSAGE-INTEGRITYpassword`

对于 WebRTC，所有这些值都通过上一章中所述的 进行分发。`Session Description`

### 候选人聚集[#](https://webrtcforthecurious.com/docs/03-connecting/#candidate-gathering)

我们现在需要收集所有可能的地址。这些地址称为候选项。

### 主机[#](https://webrtcforthecurious.com/docs/03-connecting/#host)

Host 候选项正在直接侦听本地接口。这可以是 UDP 或 TCP。

### mDNS[#](https://webrtcforthecurious.com/docs/03-connecting/#mdns)

mDNS 候选项与主机候选项类似，但 IP 地址被遮挡。您无需将您的 IP 地址通知另一方，而是为他们提供一个 UUID 作为主机名。然后，您设置一个多播侦听器，并在有人请求您发布的 UUID 时做出响应。

如果您与代理位于同一网络中，则可以通过多播找到彼此。如果您不在同一网络中，则无法连接（除非网络管理员明确配置网络以允许多播数据包遍历）。

这对于隐私目的很有用。用户可以通过 WebRTC 使用 Host 候选者找到您的本地 IP 地址（甚至无需尝试连接到您），但使用 mDNS 候选者，现在他们只能获得一个随机的 UUID。

### 服务器自反[#](https://webrtcforthecurious.com/docs/03-connecting/#server-reflexive)

通过对 STUN 服务器执行 a 来生成 Server Reflexive candidate。`STUN Binding Request`

当您得到 时，它是您的 Server Reflexive Candidate。`STUN Binding ResponseXOR-MAPPED-ADDRESS`

### 同伴自反[#](https://webrtcforthecurious.com/docs/03-connecting/#peer-reflexive)

当远程对等体从对等体以前未知的地址接收您的请求时，将创建 Peer Peer Reflexive 候选者。收到后，对等节点会将所述地址报告（反映）给您。对等体知道请求是由您而不是其他人发送的，因为 ICE 是经过身份验证的协议。

当 与 位于不同子网中的 通信时，通常会发生这种情况，这会导致创建新的子网。还记得我们说过连接检查实际上是 STUN 数据包吗？STUN 响应的格式自然允许对等体报告对等体自反地址。`Host CandidateServer Reflexive CandidateNAT mapping`

### 中继[#](https://webrtcforthecurious.com/docs/03-connecting/#relay)

中继候选者是使用 TURN 服务器生成的。

在与 TURN 服务器进行初始握手后，您将获得一个 ，这是您的 Relay Candidate。`RELAYED-ADDRESS`

### 连接检查[#](https://webrtcforthecurious.com/docs/03-connecting/#connectivity-checks)

我们现在知道远程代理的 、 和 候选项。我们现在可以尝试连接了！每个候选人都彼此配对。因此，如果您每边有 3 个候选者，那么您现在有 9 个候选对。`user fragmentpassword`

视觉上它看起来像这样：

![](https://webrtcforthecurious.com/docs/images/03-connectivity-checks.png)

### 候选人选择[#](https://webrtcforthecurious.com/docs/03-connecting/#candidate-selection)

Controlling 和 Controlled Agent 都开始在每对上发送流量。如果一个 Agent 位于 后面，则需要这样做，这将导致创建 。`Address Dependent MappingPeer Reflexive Candidate`

然后，每个看到网络流量的流量都会被提升为一对。然后，控制代理选择一对并指定它。这将成为 .然后，Controlling 和 Controlled Agent 尝试再进行一轮双向通信。如果成功，则 将变为 ！然后，此货币对将用于会话的其余部分。`Candidate PairValid CandidateValid CandidateNominated PairNominated PairSelected Candidate Pair`

### 重新 启动[#](https://webrtcforthecurious.com/docs/03-connecting/#restarts)

如果由于任何原因（NAT 映射过期、TURN 服务器崩溃）停止工作，ICE 代理将进入状态。两个代理都可以重新启动，并将重新执行整个过程。`Selected Candidate PairFailed`

# 安全[#](https://webrtcforthecurious.com/docs/04-securing/#securing)

## WebRTC 有什么安全性？[#](https://webrtcforthecurious.com/docs/04-securing/#what-security-does-webrtc-have)

每个 WebRTC 连接都经过身份验证和加密。您可以确信第三方无法看到您发送的内容或插入虚假消息。您还可以确保生成 Session Description 的 WebRTC Agent 是您正在与之通信的 WebRTC Agent。

没有人篡改这些消息非常重要。如果第三方在传输过程中读取会话描述，那是可以的。但是，WebRTC 无法防止其被修改。攻击者可以通过更改 ICE 候选项并更新证书指纹来对您执行中间人攻击。

## 它是如何工作的？[#](https://webrtcforthecurious.com/docs/04-securing/#how-does-it-work)

WebRTC 使用两个预先存在的协议，即数据报传输层安全协议 （[DTLS](https://tools.ietf.org/html/rfc6347)） 和安全实时传输协议 （[SRTP](https://tools.ietf.org/html/rfc3711)）。

DTLS 允许您协商会话，然后在两个对等体之间安全地交换数据。它是 TLS 的兄弟姐妹，TLS 的技术与 HTTPS 的技术相同，但 DTLS 使用 UDP 而不是 TCP 作为传输层。这意味着协议必须处理不可靠的传输。SRTP 专为安全地交换媒体而设计。我们可以使用它来代替 DTLS 进行一些优化。

首先使用 DTLS。它通过 ICE 提供的连接进行握手。DTLS 是一种客户端/服务器协议，因此需要一端开始握手。客户端/服务器角色是在发出信号期间选择的。在 DTLS 握手期间，双方都提供证书。 握手完成后，此证书将与 Session Description （会话描述） 中的证书哈希进行比较。这是为了确保握手发生在您预期的 WebRTC 代理上。然后，DTLS 连接可用于 DataChannel 通信。

要创建 SRTP 会话，我们使用 DTLS 生成的密钥对其进行初始化。SRTP 没有握手机制，因此必须使用外部密钥进行引导。完成此作后，就可以交换使用 SRTP 加密的媒体！

## 安全 101[#](https://webrtcforthecurious.com/docs/04-securing/#security-101)

要了解本章中介绍的技术，您需要先了解这些术语。密码学是一个棘手的话题，因此也值得咨询其他来源！

### 明文和密文[#](https://webrtcforthecurious.com/docs/04-securing/#plaintext-and-ciphertext)

Plaintext 是密码的输入。密文是密码的输出。

### 密码[#](https://webrtcforthecurious.com/docs/04-securing/#cipher)

密码是将明文转换为密文的一系列步骤。然后可以反转密码，因此您可以将密文恢复为明文。密码通常具有用于更改其行为的密钥。另一个术语是加密和解密。

一个简单的密码是 ROT13。每个字母向前移动 13 个字符。要撤消密码，请向后移动 13 个字符。明文将变为密文 。在本例中，Cipher 为 ROT，密钥为 13。`HELLOURYYB`

### 哈希函数[#](https://webrtcforthecurious.com/docs/04-securing/#hash-functions)

加密哈希函数是生成摘要的单向过程。给定一个 input，它每次都会生成相同的 output。重要的是 output *是*不可逆的。如果您有输出，则应该无法确定其输入。当您想要确认消息未被篡改时，哈希非常有用。

一个简单的（尽管肯定不适合真正的密码学）哈希函数是只取每个其他字母。 将变为 。您不能假设是输入，但您可以确认这将与哈希摘要匹配。`HELLOHLOHELLOHELLO`

### 公钥/私钥加密[#](https://webrtcforthecurious.com/docs/04-securing/#publicprivate-key-cryptography)

公钥/私钥加密 描述 DTLS 和 SRTP 使用的密码类型。在此系统中，您有两个密钥，一个公钥和私钥。公钥用于加密消息，可以安全地共享。 私钥用于解密，绝不应共享。它是唯一可以解密使用公钥加密的消息的密钥。

### Diffie-Hellman 交易所[#](https://webrtcforthecurious.com/docs/04-securing/#diffiehellman-exchange)

Diffie-Hellman 交换允许两个以前从未见过的用户通过互联网安全地创建共享密钥。用户可以向 User 发送 Secret，而不必担心被窃听。这取决于打破离散对数问题的难度。 您不需要完全了解其工作原理，但了解这就是使 DTLS 握手成为可能的原因会有所帮助。`AB`

维基百科在这里有[一个例子。](https://en.wikipedia.org/wiki/Diffie%E2%80%93Hellman_key_exchange#Cryptographic_explanation)

### 伪随机函数[#](https://webrtcforthecurious.com/docs/04-securing/#pseudorandom-function)

伪随机函数 （PRF） 是一个预定义的函数，用于生成看起来随机的值。它可能需要多个输入并生成单个输出。

### 密钥派生函数[#](https://webrtcforthecurious.com/docs/04-securing/#key-derivation-function)

Key Derivation 是一种伪随机函数。Key Derivation 是一种用于使 key 更强大的函数。一种常见的模式是键拉伸。

假设您获得一个 8 字节的密钥。您可以使用 KDF 使其更坚固。

### 随机数[#](https://webrtcforthecurious.com/docs/04-securing/#nonce)

nonce 是密码的附加输入。这样，即使您多次加密同一消息，也可以从密码获得不同的输出。

如果您加密相同的消息 10 次，则密码将为您提供相同的密文 10 次。通过使用 nonce，您可以获得不同的输出，同时仍然使用相同的 key。为每条消息使用不同的 nonce 很重要！否则，它将否定大部分值。

### 消息认证码[#](https://webrtcforthecurious.com/docs/04-securing/#message-authentication-code)

消息身份验证代码是放置在消息末尾的哈希值。MAC 证明该消息来自您预期的用户。

如果您不使用 MAC，攻击者可能会插入无效消息。解密后，你只会有垃圾，因为他们不知道密钥。

### 密钥轮换[#](https://webrtcforthecurious.com/docs/04-securing/#key-rotation)

密钥轮换是每隔一段时间更改密钥的做法。这使得被盗密钥的影响较小。如果密钥被盗或泄露，则可以解密的数据更少。

## DTLS 系列[#](https://webrtcforthecurious.com/docs/04-securing/#dtls)

DTLS（数据报传输层安全性）允许两个对等体在没有预先存在的配置的情况下建立安全通信。即使有人偷听对话，他们也无法解密消息。

要使 DTLS 客户端和服务器进行通信，它们需要就密码和密钥达成一致。它们通过执行 DTLS 握手来确定这些值。在握手期间，消息以明文形式显示。 当 DTLS 客户端/服务器交换了足够的详细信息以开始加密时，它会发送一个 .在此消息之后，每个后续消息都将被加密！`Change Cipher Spec`

### 数据包格式[#](https://webrtcforthecurious.com/docs/04-securing/#packet-format)

每个 DTLS 数据包都以标头开头。

### 内容类型[#](https://webrtcforthecurious.com/docs/04-securing/#content-type)

您可以期待以下类型：

- `20`
    - 更改密码规范
- `22`
    - 握手
- `23`
    - 应用程序数据

`Handshake`用于交换详细信息以启动会话。 用于通知对方所有内容都将被加密。 是加密的消息。`Change Cipher SpecApplication Data`

### 版本[#](https://webrtcforthecurious.com/docs/04-securing/#version)

版本可以是 （DTLS v1.0） 或 （DTLS v1.2），没有 v1.1。`0x0000feff0x0000fefd`

### 时代[#](https://webrtcforthecurious.com/docs/04-securing/#epoch)

纪元从 开始，但在 之后变为 。任何具有非零纪元的消息都会被加密。`01Change Cipher Spec`

### 序列号[#](https://webrtcforthecurious.com/docs/04-securing/#sequence-number)

序列号 用于保持消息的顺序。每条消息都会增加 Sequence Number。当纪元递增时，序列号将重新开始。

### 长度和有效载荷[#](https://webrtcforthecurious.com/docs/04-securing/#length-and-payload)

Payload 是特定的。对于 a 是加密数据。因为它会根据消息而有所不同。长度是关于它有多大。`Content TypeApplication DataPayloadHandshakePayload`

### 握手状态机[#](https://webrtcforthecurious.com/docs/04-securing/#handshake-state-machine)

在握手期间，客户端/服务器交换一系列消息。这些消息分为 Flight。每个航班中可能有多条消息（或只有一条）。 在收到 Flight 中的所有消息之前，Flight 不会完成。我们将在下面更详细地描述每条消息的用途。

![](https://webrtcforthecurious.com/docs/images/04-handshake.png)

### 客户端你好[#](https://webrtcforthecurious.com/docs/04-securing/#clienthello)

ClientHello 是客户端发送的初始消息。它包含一个属性列表。这些属性告诉服务器客户端支持的密码和功能。对于 WebRTC，这也是我们选择 SRTP 密码的方式。它还包含将用于生成会话密钥的随机数据。

### HelloVerifyRequest 请求[#](https://webrtcforthecurious.com/docs/04-securing/#helloverifyrequest)

HelloVerifyRequest 由服务器发送到客户端。这是为了确保客户端打算发送请求。然后，Client 重新发送 ClientHello，但使用 HelloVerifyRequest 中提供的令牌。

### 服务器Hello[#](https://webrtcforthecurious.com/docs/04-securing/#serverhello)

ServerHello 是服务器对此会话配置的响应。它包含此会话结束时将使用的密码。它还包含服务器随机数据。

### 证书[#](https://webrtcforthecurious.com/docs/04-securing/#certificate)

Certificate 包含客户端或服务器的证书。这用于唯一标识我们与谁通信。握手结束后，我们将确保此证书在经过哈希处理时与 .`SessionDescription`

### ServerKeyExchange/ClientKeyExchange的[#](https://webrtcforthecurious.com/docs/04-securing/#serverkeyexchangeclientkeyexchange)

这些消息用于传输公钥。启动时，客户端和服务器都会生成一个密钥对。握手后，这些值将用于生成 .`Pre-Master Secret`

### 证书请求[#](https://webrtcforthecurious.com/docs/04-securing/#certificaterequest)

服务器发送 CertificateRequest，通知客户端它需要证书。服务器可以 Request （请求） 或 Require a certificate （需要证书）。

### ServerHelloDone 服务器[#](https://webrtcforthecurious.com/docs/04-securing/#serverhellodone)

ServerHelloDone 通知客户端服务器已完成握手。

### 证书验证[#](https://webrtcforthecurious.com/docs/04-securing/#certificateverify)

CertificateVerify 是发件人证明其具有 Certificate 消息中发送的私有密钥的方式。

### 更改密码规范[#](https://webrtcforthecurious.com/docs/04-securing/#changecipherspec)

ChangeCipherSpec 通知接收者，在此消息之后发送的所有内容都将被加密。

### 完成[#](https://webrtcforthecurious.com/docs/04-securing/#finished)

Finished 已加密并包含所有消息的哈希值。这是为了断言握手没有被篡改。

### 密钥生成[#](https://webrtcforthecurious.com/docs/04-securing/#key-generation)

握手完成后，您可以开始发送加密数据。密码由服务器选择，位于 ServerHello 中。不过，钥匙是如何选择的呢？

首先，我们生成 .为了获得此值，对 和 交换的密钥使用 Diffie–Hellman。详细信息因所选的 Cipher 而异。`Pre-Master SecretServerKeyExchangeClientKeyExchange`

接下来生成。DTLS 的每个版本都有一个定义的 .对于 DTLS 1.2，该函数采用 和 中的 和 随机值。 运行 的输出是 。这是用于 Cipher 的值。`Master SecretPseudorandom functionPre-Master SecretClientHelloServerHelloPseudorandom FunctionMaster SecretMaster Secret`

### 交换 ApplicationData[#](https://webrtcforthecurious.com/docs/04-securing/#exchanging-applicationdata)

DTLS 的主力是 。现在我们已经有了初始化的密码，我们可以开始加密和发送值了。`ApplicationData`

`ApplicationData`消息使用 DTLS 标头，如前所述。其中填充了密文。现在，您有一个有效的 DTLS 会话，并且可以安全地进行通信。`Payload`

DTLS 还有许多更有趣的功能，例如重新协商。WebRTC 不使用它们，因此这里不介绍它们。

## SRTP[#](https://webrtcforthecurious.com/docs/04-securing/#srtp)

SRTP 是专为加密 RTP 数据包而设计的协议。要启动 SRTP 会话，请指定密钥和密码。与 DTLS 不同，它没有握手机制。所有配置和密钥都是在 DTLS 握手期间生成的。

DTLS 提供了一个专用的 API 来导出密钥以供其他进程使用。这在 [RFC 5705](https://tools.ietf.org/html/rfc5705) 中定义。

### 会话创建[#](https://webrtcforthecurious.com/docs/04-securing/#session-creation)

SRTP 定义了一个用于输入的密钥派生函数。创建 SRTP 会话时，将运行输入，以生成 SRTP 密码的密钥。在此之后，您可以继续处理媒体。

### 交换媒体[#](https://webrtcforthecurious.com/docs/04-securing/#exchanging-media)

每个 RTP 数据包都有一个 16 位 SequenceNumber。这些序列号用于保持数据包的顺序，就像主密钥一样。在通话期间，这些将翻转。SRTP 会跟踪它并将其称为翻转计数器。

加密数据包时，SRTP 使用翻转计数器和序列号作为 nonce。这是为了确保即使您两次发送相同的数据，密文也会有所不同。这对于防止攻击者识别模式或尝试重放攻击非常重要。

# 实时联网[#](https://webrtcforthecurious.com/docs/05-real-time-networking/#real-time-networking)

## 为什么网络在实时通信中如此重要？[#](https://webrtcforthecurious.com/docs/05-real-time-networking/#why-is-networking-so-important-in-real-time-communication)

网络是实时通信的限制因素。在理想的世界中，我们将拥有无限的带宽 数据包将立即到达。但事实并非如此。网络受到限制，条件 可能随时更改。测量和观察网络状况也是一个难题。您可以获得不同的行为 取决于硬件、软件和 IT 配置。

实时通信也带来了一个在大多数其他领域中不存在的问题。对于 Web 开发人员来说，这并不是致命的 如果您的网站在某些网络上速度较慢。只要所有数据都到达，用户就会很高兴。使用 WebRTC 时，如果您的数据是 迟到没用。没有人关心 5 秒前在电话会议中说了什么。因此，在开发实时通信系统时， 你必须做出权衡。我的时间限制是多少，我可以发送多少数据？

本章介绍适用于数据和媒体通信的概念。在后面的章节中，我们将超越 理论并讨论 WebRTC 的媒体和数据子系统如何解决这些问题。

## 网络的哪些属性使其变得困难？[#](https://webrtcforthecurious.com/docs/05-real-time-networking/#what-are-the-attributes-of-the-network-that-make-it-difficult)

在所有网络中有效工作的代码很复杂。你有很多不同的因素，它们 都可以微妙地相互影响。这些是开发人员将遇到的最常见问题。

### 带宽[#](https://webrtcforthecurious.com/docs/05-real-time-networking/#bandwidth)

带宽 是可以通过给定路径传输的最大数据速率。记住这一点很重要 这也不是一个静态数字。带宽会随着更多（或更少）的人使用而沿路线发生变化。

### 传输时间和往返时间[#](https://webrtcforthecurious.com/docs/05-real-time-networking/#transmission-time-and-round-trip-time)

传输时间是数据包到达目的地所需的时间。与 Bandwidth 一样，这不是恒定的。传输时间随时可能波动。

`transmission_time = receive_time - send_time`

要计算传输时间，您需要以毫秒精度同步发送方和接收方的时钟。 即使是很小的偏差也会产生不可靠的传输时间测量。 由于 WebRTC 在高度异构的环境中运行，因此几乎不可能依赖主机之间的完美时间同步。

Round-trip time measurement 是 clock synchronization不完美的解决方法。

WebRTC 对等体不是在分布式时钟上运行，而是发送一个带有自己的 timestamp 的特殊数据包。 合作对等体接收数据包并将时间戳反射回发送方。 原始发送者获得反射时间后，它会从当前时间中减去时间戳。 这个时间增量称为 “round-trip propagation delay” 或更常见的 roundtrip time。`sendertime1sendertime1sendertime2`

`rtt = sendertime2 - sendertime1`

往返时间的一半被认为是传输时间的足够好的近似值。 此解决方法并非没有缺点。 它假设发送和接收数据包所需的时间相同。 但是，在蜂窝网络上，发送和接收作可能不是时间对称的。 您可能已经注意到，手机上的上传速度几乎总是低于下载速度。

`transmission_time = rtt/2`

往返时间测量的技术细节在 [RTCP 发送方和接收方报告 一章](https://webrtcforthecurious.com/docs/06-media-communication/#receiver-reports--sender-reports)中有更详细的介绍。

### 抖动[#](https://webrtcforthecurious.com/docs/05-real-time-networking/#jitter)

抖动是每个数据包可能不同的事实。您的数据包可能会延迟，但随后会以突发形式到达。`Transmission Time`

### 数据包丢失[#](https://webrtcforthecurious.com/docs/05-real-time-networking/#packet-loss)

数据包丢失是指消息在传输过程中丢失。损失可能是稳定的，也可能是尖峰式的。 这可能是由于网络类型（如卫星或 Wi-Fi）造成的。或者它可能在此过程中由软件引入。

### 最大传输单位[#](https://webrtcforthecurious.com/docs/05-real-time-networking/#maximum-transmission-unit)

Maximum Transmission Unit （最大传输单位） 是单个数据包的大小限制。网络不允许发送 一条巨大的信息。在协议级别，可能必须将消息拆分为多个较小的数据包。

The MTU will also differ depending on what network path you take. You can use a protocol like [Path MTU Discovery](https://tools.ietf.org/html/rfc1191) to figure out the largest packet size you can send.

### Congestion [#](https://webrtcforthecurious.com/docs/05-real-time-networking/#congestion)

Congestion is when the limits of the network have been reached. This is usually because you have reached the peak bandwidth that the current route can handle. Or it could be operator imposed like hourly limits your ISP configures.

Congestion exhibits itself in many different ways. There is no standardized behavior. In most cases when congestion is reached the network will drop excess packets. In other cases the network will buffer. This will cause the Transmission Time for your packets to increase. You could also see more jitter as your network becomes congested. This is a rapidly changing area and new algorithms for congestion detection are still being written.

### Dynamic [#](https://webrtcforthecurious.com/docs/05-real-time-networking/#dynamic)

Networks are incredibly dynamic and conditions can change rapidly. During a call you may send and receive hundreds of thousands of packets. Those packets will be traveling through multiple hops. Those hops will be shared by millions of other users. Even in your local network you could have HD movies being downloaded or maybe a device decides to download a software update.

Having a good call isn’t as simple as measuring your network on startup. You need to be constantly evaluating. You also need to handle all the different behaviors that come from a multitude of network hardware and software.

## Solving Packet Loss [#](https://webrtcforthecurious.com/docs/05-real-time-networking/#solving-packet-loss)

Handling packet loss is the first problem to solve. There are multiple ways to solve it, each with their own benefits. It depends on what you are sending and how latency tolerant you are. It is also important to note that not all packet loss is fatal. Losing some video might not be a problem, the human eye might not even able to perceive it. Losing a users text messages are fatal.

Let’s say you send 10 packets, and packets 5 and 6 are lost. Here are the ways you can solve it.

### Acknowledgments [#](https://webrtcforthecurious.com/docs/05-real-time-networking/#acknowledgments)

Acknowledgments is when the receiver notifies the sender of every packet they have received. The sender is aware of packet loss when it gets an acknowledgment for a packet twice that isn’t final. When the sender gets an for packet 4 twice, it knows that packet 5 has not been seen yet.`ACK`

### Selective Acknowledgments [#](https://webrtcforthecurious.com/docs/05-real-time-networking/#selective-acknowledgments)

Selective Acknowledgments is an improvement upon Acknowledgments. A receiver can send a that acknowledges multiple packets and notifies the sender of gaps. Now the sender can get a for packet 4 and 7. It then knows it needs to re-send packets 5 and 6.`SACKSACK`

### Negative Acknowledgments [#](https://webrtcforthecurious.com/docs/05-real-time-networking/#negative-acknowledgments)

Negative Acknowledgments solve the problem the opposite way. Instead of notifying the sender what it has received, the receiver notifies the sender what has been lost. In our case a will be sent for packets 5 and 6. The sender only knows packets the receiver wishes to have sent again.`NACK`

### Forward Error Correction [#](https://webrtcforthecurious.com/docs/05-real-time-networking/#forward-error-correction)

Forward Error Correction fixes packet loss pre-emptively. The sender sends redundant data, meaning a lost packet doesn’t affect the final stream. One popular algorithm for this is Reed–Solomon error correction.

This reduces the latency/complexity of sending and handling Acknowledgments. Forward Error Correction is a waste of bandwidth if the network you are in has zero loss.

## Solving Jitter [#](https://webrtcforthecurious.com/docs/05-real-time-networking/#solving-jitter)

Jitter is present in most networks. Even inside a LAN you have many devices sending data at fluctuating rates. You can easily observe jitter by pinging another device with the command and noticing the fluctuations in round-trip latency.`ping`

To solve jitter, clients use a JitterBuffer. The JitterBuffer ensures a steady delivery time of packets. The downside is that JitterBuffer adds some latency to packets that arrive early. The upside is that late packets don’t cause jitter. Imagine that during a call, you see the following packet arrival times:

```
* time=1.46 ms
* time=1.93 ms
* time=1.57 ms
* time=1.55 ms
* time=1.54 ms
* time=1.72 ms
* time=1.45 ms
* time=1.73 ms
* time=1.80 ms

```

在这种情况下，大约 1.8 毫秒将是一个不错的选择。延迟到达的数据包将使用我们的延迟窗口。提前到达的数据包会延迟一点，并且可能会 填满被延迟数据包耗尽的窗口。这意味着我们不再有卡顿，为客户提供平稳的交货率。

### JitterBuffer作[#](https://webrtcforthecurious.com/docs/05-real-time-networking/#jitterbuffer-operation)

![](https://webrtcforthecurious.com/docs/images/05-jitterbuffer.png)

每个数据包在收到后立即添加到抖动缓冲区中。 一旦有足够的数据包来重建帧，构成该帧的数据包就会从缓冲区中释放并发出以进行解码。 反过来，解码器对用户屏幕上的视频帧进行解码和绘制。 由于抖动缓冲区的容量有限，因此在缓冲区中停留时间过长的数据包将被丢弃。

[在媒体通信章节中](https://webrtcforthecurious.com/docs/06-media-communication/#rtp)阅读更多关于如何将视频帧转换为 RTP 数据包，以及为什么需要重建的信息。

`jitterBufferDelay`可以深入了解您的网络性能及其对播放平滑度的影响。 它是与接收方的入站流相关的 [WebRTC 统计 API](https://www.w3.org/TR/webrtc-stats/#dom-rtcinboundrtpstreamstats-jitterbufferdelay) 的一部分。 延迟定义视频帧在发出进行解码之前在抖动缓冲区中花费的时间。 较长的抖动缓冲区延迟意味着您的网络高度拥塞。

## 检测拥塞[#](https://webrtcforthecurious.com/docs/05-real-time-networking/#detecting-congestion)

在我们解决拥塞问题之前，我们需要检测它。为了检测它，我们使用拥塞控制器。这是一个复杂的主题，并且仍在迅速变化。 新算法仍在发布和测试中。在高层次上，他们的运作方式都是一样的。拥塞控制器在给定一些输入的情况下提供带宽估计。 以下是一些可能的输入：

- **数据包丢失** - 当网络变得拥塞时，数据包被丢弃。
- **抖动** - 随着网络设备变得更加过载，数据包排队将导致时间不稳定。
- **往返时间** - 拥塞时，数据包需要更长的时间才能到达。与抖动不同，Round Trip Time 只是不断增加。
- **显式拥塞通知** - 较新的网络可能会将数据包标记为有被丢弃的风险，以缓解拥塞。

在通话期间需要连续测量这些值。网络利用率可能会增加或减少，因此可用带宽可能会不断变化。

## 解决拥塞[#](https://webrtcforthecurious.com/docs/05-real-time-networking/#resolving-congestion)

现在我们有了估计的带宽，我们需要调整我们发送的内容。我们如何调整取决于我们想要发送的数据类型。

### 发送速度变慢[#](https://webrtcforthecurious.com/docs/05-real-time-networking/#sending-slower)

限制发送数据的速度是防止拥塞的第一个解决方案。拥塞控制器为您提供一个估计值，它是 发件人对速率限制的责任。

这是大多数数据通信使用的方法。对于像 TCP 这样的协议，这一切都由作系统完成，并且对用户和开发人员都是完全透明的。

### 发送更少[#](https://webrtcforthecurious.com/docs/05-real-time-networking/#sending-less)

在某些情况下，我们可以发送更少的信息来满足我们的限制。我们对数据到达也有严格的截止日期，因此我们不能发送得更慢。这些是约束 实时媒体属于。

如果我们没有足够的可用带宽，我们就可以降低我们发送的视频质量。这需要视频编码器和拥塞控制器之间有一个紧密的反馈循环。

# 媒体传播[#](https://webrtcforthecurious.com/docs/06-media-communication/#media-communication)

## WebRTC 的媒体通信中得到了什么？[#](https://webrtcforthecurious.com/docs/06-media-communication/#what-do-i-get-from-webrtcs-media-communication)

WebRTC 允许您发送和接收无限数量的音频和视频流。您可以在通话期间随时添加和删除这些流。这些流可以是独立的，也可以是捆绑在一起的！您可以发送桌面的视频源，然后包含来自网络摄像头的音频和视频。

WebRTC 协议与编解码器无关。底层传输支持一切，甚至是尚不存在的东西！但是，您正在与之通信的 WebRTC 代理可能没有必要的工具来接受它。

WebRTC 还旨在处理动态网络条件。在通话期间，您的带宽可能会增加或减少。也许您突然遇到了很多数据包丢失。该协议旨在处理所有这些。WebRTC 会响应网络状况，并尝试为您提供可用资源的最佳体验。

## 它是如何工作的？[#](https://webrtcforthecurious.com/docs/06-media-communication/#how-does-it-work)

WebRTC 使用两个预先存在的协议 RTP 和 RTCP，这两个协议都在 [RFC 1889](https://tools.ietf.org/html/rfc1889) 中定义。

RTP（实时传输协议）是传输媒体的协议。它旨在允许实时传输视频。它没有规定任何关于延迟或可靠性的规则，但为您提供了实现这些规则的工具。RTP 为您提供流，因此您可以通过一个连接运行多个媒体源。它还为您提供馈送媒体管道所需的计时和排序信息。

RTCP（RTP 控制协议）是传达有关呼叫的元数据的协议。该格式非常灵活，允许您添加所需的任何元数据。这用于传达有关调用的统计信息。它还用于处理数据包丢失和实施拥塞控制。它为您提供响应不断变化的网络条件所需的双向通信。

## 延迟与质量[#](https://webrtcforthecurious.com/docs/06-media-communication/#latency-vs-quality)

实时媒体是指在延迟和质量之间进行权衡。您愿意容忍的延迟越多，您预期的视频质量就越高。

### 现实世界的限制[#](https://webrtcforthecurious.com/docs/06-media-communication/#real-world-limitations)

这些约束都是由现实世界的限制引起的。它们都是您需要克服的网络特征。

### 视频很复杂[#](https://webrtcforthecurious.com/docs/06-media-communication/#video-is-complex)

传输视频并不容易。要存储 30 分钟的未压缩 720 8 位视频，您需要大约 110 GB。有了这些数字，4 人电话会议就不会发生。我们需要一种方法来缩小它，而答案是视频压缩。不过，这并非没有缺点。

## 视频 101[#](https://webrtcforthecurious.com/docs/06-media-communication/#video-101)

我们不会深入介绍视频压缩，但足以理解为什么 RTP 是这样设计的。视频压缩将视频编码为一种新格式，该格式需要更少的位来表示相同的视频。

### 有损和无损压缩[#](https://webrtcforthecurious.com/docs/06-media-communication/#lossy-and-lossless-compression)

您可以将视频编码为无损（不会丢失任何信息）或有损（信息可能会丢失）。由于无损编码需要将更多数据发送到对等体，从而导致更高的延迟流和更多的丢包，因此 RTP 通常使用有损压缩，即使视频质量不会那么好。

### 帧内和帧间压缩[#](https://webrtcforthecurious.com/docs/06-media-communication/#intra-and-inter-frame-compression)

视频压缩有两种类型。第一个是帧内。帧内压缩减少了用于描述单个视频帧的比特。相同的技术用于压缩静止图片，如 JPEG 压缩方法。

第二种类型是帧间压缩。由于视频由许多图片组成，因此我们想方设法避免两次发送相同的信息。

### 帧间类型[#](https://webrtcforthecurious.com/docs/06-media-communication/#inter-frame-types)

然后，有三种框架类型：

- **I 帧** - 一张完整的图片，无需任何其他内容即可解码。
- **P 帧** - 部分图片，仅包含与上一张图片相比的更改。
- **B 框架** - 部分图片，是对以前和未来图片的修改。

以下是三种帧类型的可视化。

![](https://webrtcforthecurious.com/docs/images/06-frame-types.png)

### 视频很精致[#](https://webrtcforthecurious.com/docs/06-media-communication/#video-is-delicate)

视频压缩具有令人难以置信的状态，因此很难通过 Internet 传输。如果您丢失了 I 型框架的一部分，会发生什么情况？P 型框架如何知道要修改什么？随着视频压缩变得越来越复杂，这变得越来越成为一个问题。幸运的是，RTP 和 RTCP 有解决方案。

## RTP[#](https://webrtcforthecurious.com/docs/06-media-communication/#rtp)

### 数据包格式[#](https://webrtcforthecurious.com/docs/06-media-communication/#packet-format)

每个 RTP 数据包都有以下结构：

```
 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|V=2|P|X|  CC   |M|     PT      |       Sequence Number         |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                           Timestamp                           |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|           Synchronization Source (SSRC) identifier            |
+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+=+
|            Contributing Source (CSRC) identifiers             |
|                             ....                              |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                            Payload                            |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

```

### 版本 （V）[#](https://webrtcforthecurious.com/docs/06-media-communication/#version-v)

`Version`总是`2`

### 填充 （P）[#](https://webrtcforthecurious.com/docs/06-media-communication/#padding-p)

`Padding`是一个 bool 值，用于控制负载是否具有填充。

有效负载的最后一个字节包含已添加的填充字节数的计数。

### 扩展 （X）[#](https://webrtcforthecurious.com/docs/06-media-communication/#extension-x)

如果设置，则 RTP 标头将具有扩展名。下面将对此进行更详细的描述。

### CSRC 计数 （CC）[#](https://webrtcforthecurious.com/docs/06-media-communication/#csrc-count-cc)

在 和 payload 之后的标识符数量。`CSRCSSRC`

### 标记 （M）[#](https://webrtcforthecurious.com/docs/06-media-communication/#marker-m)

标记位没有预设的含义，用户可以随心所欲地使用。

在某些情况下，它是在用户说话时设置的。它也常用于标记关键帧。

### 有效载荷类型 （PT）[#](https://webrtcforthecurious.com/docs/06-media-communication/#payload-type-pt)

`Payload Type`是此数据包所携带的编解码器的唯一标识符。

对于 WebRTC 来说，它是动态的。一个调用中的 VP8 可能与另一个调用不同。调用中的提供方确定 到 的映射到 中的 编解码器。`Payload TypePayload TypesSession Description`

### 序列号[#](https://webrtcforthecurious.com/docs/06-media-communication/#sequence-number)

`Sequence Number`用于对流中的数据包进行排序。每次发送数据包时，都会增加 1。`Sequence Number`

RTP 旨在用于有损网络。这为接收方提供了一种检测数据包何时丢失的方法。

### 时间戳[#](https://webrtcforthecurious.com/docs/06-media-communication/#timestamp)

此数据包的采样时刻。这不是全局时钟，而是媒体流中经过的时间。例如，如果多个 RTP 数据包都属于同一视频帧，则它们可以具有相同的时间戳。

### 同步源 （SSRC）[#](https://webrtcforthecurious.com/docs/06-media-communication/#synchronization-source-ssrc)

An 是此流的唯一标识符。这允许通过单个 RTP 流运行多个媒体流。`SSRC`

### 贡献源 （CSRC）[#](https://webrtcforthecurious.com/docs/06-media-communication/#contributing-source-csrc)

一个列表，用于传达 es 对此数据包的贡献。`SSRC`

这通常用于谈话指标。假设在服务器端，您将多个音频源合并到一个 RTP 流中。然后，您可以使用此字段说“输入流 A 和 C 此时正在交谈”。

### 有效载荷[#](https://webrtcforthecurious.com/docs/06-media-communication/#payload)

实际负载数据。如果设置了 padding 标志，则可能以添加的填充字节数结束。

### 扩展[#](https://webrtcforthecurious.com/docs/06-media-communication/#extensions)

## RTCP[#](https://webrtcforthecurious.com/docs/06-media-communication/#rtcp)

### 数据包格式[#](https://webrtcforthecurious.com/docs/06-media-communication/#packet-format-1)

每个 RTCP 数据包都有以下结构：

```
 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|V=2|P|    RC   |       PT      |             length            |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                            Payload                            |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+

```

### 版本 （V）[#](https://webrtcforthecurious.com/docs/06-media-communication/#version-v-1)

`Version`始终 。`2`

### 填充 （P）[#](https://webrtcforthecurious.com/docs/06-media-communication/#padding-p-1)

`Padding`是一个 bool 值，用于控制负载是否具有填充。

有效负载的最后一个字节包含已添加的填充字节数的计数。

### 接收报告计数 （RC）[#](https://webrtcforthecurious.com/docs/06-media-communication/#reception-report-count-rc)

此数据包中的报告数。单个 RTCP 数据包可以包含多个事件。

### 数据包类型 （PT）[#](https://webrtcforthecurious.com/docs/06-media-communication/#packet-type-pt)

这是 RTCP 数据包类型的唯一标识符。WebRTC 代理不需要支持所有这些类型，代理之间的支持可能不同。不过，这些是您可能经常看到的：

- `192FIR`)
    - 完整的帧内请求 （
- `193NACK`)
    - 负 ACKnowledgements （
- `200`
    - 发件人报告
- `201`
    - 接收方报告
- `205`
    - 通用 RTP 反馈
- `206`
    - 特定于有效负载的反馈

下面将更详细地介绍这些数据包类型的重要性。

### 完整的帧内请求 （FIR） 和图片丢失指示 （PLI）[#](https://webrtcforthecurious.com/docs/06-media-communication/#full-intra-frame-request-fir-and-picture-loss-indication-pli)

两者和 messages 的用途相似。这些消息向发件人请求完整的关键帧。 在将部分帧提供给解码器但无法对其进行解码时使用。 这可能是因为您丢失了大量数据包，或者解码器崩溃了。`FIRPLIPLI`

根据 [RFC 5104](https://tools.ietf.org/html/rfc5104#section-4.3.1.2)，当数据包或帧丢失时，不应使用。那是我的工作。 请求关键帧的原因不是丢包，例如当新成员进入视频会议时。它们需要一个完整的关键帧来开始解码视频流，解码器将丢弃帧，直到关键帧到达。`FIRPLIFIR`

接收器最好在连接后立即请求完整的关键帧，这样可以最大限度地减少连接与图像显示在用户屏幕上之间的延迟。

`PLI`数据包是 Payload Specific Feedback 消息的一部分。

在实践中，能够同时处理 和 数据包的软件在这两种情况下将以相同的方式运行。它将向编码器发送信号以生成新的完整关键帧。`PLIFIR`

### 否定确认[#](https://webrtcforthecurious.com/docs/06-media-communication/#negative-acknowledgment)

A 请求发送方重新传输单个 RTP 数据包。这通常是由于 RTP 数据包丢失引起的，但也可能是因为它很晚。`NACK`

`NACK`的带宽效率比请求再次发送整个帧要高效得多。由于 RTP 将数据包分解成非常小的块，因此您实际上只是请求一个小的缺失部分。接收方使用 SSRC 和 Sequence Number 创建 RTCP 消息。如果发送方没有可重新发送的 RTP 数据包，则只会忽略该消息。

### 发件人和收件人报告[#](https://webrtcforthecurious.com/docs/06-media-communication/#sender-and-receiver-reports)

这些报告用于在代理之间发送统计信息。这传达了实际接收的数据包数量和抖动。

这些报告可用于诊断和拥塞控制。

## RTP/RTCP 如何共同解决问题[#](https://webrtcforthecurious.com/docs/06-media-communication/#how-rtprtcp-solve-problems-together)

然后，RTP 和 RTCP 协同工作，解决由网络引起的所有问题。这些技术仍在不断变化！

### 前向纠错[#](https://webrtcforthecurious.com/docs/06-media-communication/#forward-error-correction)

也称为 FEC。另一种处理数据包丢失的方法。FEC 是指您多次发送相同的数据，甚至没有请求。这是在 RTP 级别完成的，甚至在编解码器级别更低。

如果呼叫的丢包率稳定，则 FEC 是比 NACK 低得多的延迟解决方案。对于 NACK 来说，必须请求然后重新传输丢失的数据包的往返时间可能很重要。

### 自适应比特率和带宽估计[#](https://webrtcforthecurious.com/docs/06-media-communication/#adaptive-bitrate-and-bandwidth-estimation)

如 [Real-time networking](https://webrtcforthecurious.com/docs/05-real-time-networking/) 一章所述，网络是不可预测且不可靠的。带宽可用性在整个会话中可能会更改多次。 在一秒钟内看到可用带宽发生巨大变化（数量级）的情况并不少见。

主要思想是根据预测的、当前和未来的可用网络带宽调整编码比特率。 这可确保传输最佳质量的视频和音频信号，并且不会因网络拥塞而断开连接。 对网络行为进行建模并尝试预测它的启发式方法称为带宽估计。

这其中有很多细微差别，所以让我们更详细地探讨一下。

## 识别和传达网络状态[#](https://webrtcforthecurious.com/docs/06-media-communication/#identifying-and-communicating-network-status)

RTP/RTCP 在所有类型的不同网络上运行，因此，它对某些人来说很常见 通信在从发送方到接收方的途中被丢弃。构建在 UDP 之上， 没有用于数据包重传的内置机制，更不用说处理拥塞控制了。

为了向用户提供最佳体验，WebRTC 必须估计有关网络路径的质量，并且 适应这些品质如何随时间变化。要监控的关键特征包括：可用 带宽（在每个方向上，因为它可能不对称）、往返时间和抖动（波动 在往返时间内）。它需要考虑数据包丢失，并传达这些数据包中的更改 属性。

这些协议有两个主要目标：

1. 估计网络支持的可用带宽（在每个方向上）。
2. 在发送方和接收方之间传达网络特性。

RTP/RTCP 有三种不同的方法来解决此问题。他们都有其优点和缺点， 一般来说，每一代人都比其前辈有所进步。您使用的实现将 主要取决于客户端可用的软件堆栈和可用于的库 构建您的应用程序。

### 接收方报告 / 发件人报告[#](https://webrtcforthecurious.com/docs/06-media-communication/#receiver-reports--sender-reports)

第一个实现是 Receiver Reports 对及其补充 Sender Reports。这些 RTCP 消息在 [RFC 3550](https://tools.ietf.org/html/rfc3550#section-6.4) 中定义，并且是 负责在终端节点之间传达网络状态。接收方报告侧重于 有关网络的通信质量（包括数据包丢失、往返时间和抖动），以及 它与其他算法配对，然后负责根据 这些报告。

发送方和接收方报告（SR 和 RR）共同描绘了网络质量的图景。他们是 按计划为每个 SSRC 发送，它们是估计可用时使用的输入 带宽。这些估计值是由发送者在收到 RR 数据后做出的，其中包含 以下字段：

- **丢失的分数** - 自上次接收方报告以来丢失的数据包的百分比。
- **Cumulative Number of Packets Lost （累积丢失的数据包数**） - 在整个呼叫期间丢失的数据包数。
- **Extended Highest Sequence Number Received** — 收到的最后一个序列号是什么，以及 它已经翻了多少次了。
- **到达间抖动** - 整个呼叫的滚动抖动。
- **Last Sender Report Timestamp** — 发件人的最后一个已知时间，用于往返时间 计算。

SR 和 RR 协同工作以计算往返时间。

发送方在 SR 中包含其本地时间。当接收方收到 SR 数据包时，它会 发回 RR。此外，RR 还包括 Just received from sender. 在接收 SR 和发送 RR 之间会有延迟。正因为如此，RR 还 包括“自上次发件人报告以来的延迟”时间 - 。用于调整 往返时间估计值。发送方收到 RR 后，它会从当前时间 中减去 和 。这个时间 delta 称为 往返 propagation delay 或 round-trip time。`sendertime1sendertime1DLSRDLSRsendertime1DLSRsendertime2`

`rtt = sendertime2 - sendertime1 - DLSR`

简单易懂的英语往返时间：

- 我给你发了一条消息，上面有我时钟的当前读数，比如说现在是下午 4：20,42 秒零 420 毫秒。
- 您将相同的时间戳发回给我。
- 您还包括从阅读我的消息到将消息发回所经过的时间，例如 5 毫秒。
- 一旦我收到时间，我就会再次查看时钟。
- 现在我的时钟显示下午 4：20,42 秒 690 毫秒。
- 这意味着我花了 265 毫秒 （690 - 420 - 5） 才到达您并返回给我。
- 因此，往返时间为 265 毫秒。

![](https://webrtcforthecurious.com/docs/images/06-rtt.png)

### TMMBR、TMMBN、REMB 和 TWCC，与 GCC 配对[#](https://webrtcforthecurious.com/docs/06-media-communication/#tmmbr-tmmbn-remb-and-twcc-paired-with-gcc)

### Google 拥塞控制 （GCC）[#](https://webrtcforthecurious.com/docs/06-media-communication/#google-congestion-control-gcc)

Google 拥塞控制 （GCC） 算法（在 [draft-ietf-rmcat-gcc-02](https://tools.ietf.org/html/draft-ietf-rmcat-gcc-02) 中概述）解决了 带宽估计的挑战。它与各种其他协议配对，以促进 相关的通信要求。因此，它非常适合在 接收端（与 TMMBR/TMMBN 或 REMB 一起运行时）或发送端（与 TWCC 一起运行时）。

为了估计可用带宽，GCC 侧重于数据包丢失和帧波动 到达时间作为其两个主要量度。它通过两个链接的控制器运行这些指标： 基于 loss 的 controller 和基于 delay 的 controller 。

GCC 的第一个组件，即基于损失的控制器，很简单：

- 如果丢包率高于 10%，则带宽估计值会降低。
- 如果数据包丢失率介于 2-10% 之间，则带宽估计值保持不变。
- 如果丢包率低于 2%，则带宽估计值会增加。

经常进行数据包丢失测量。根据配对的通信协议， 数据包丢失可以是显式通信的（如 TWCC）或推断的（如 TMMBR/TMMBN 和 REMB）。这些百分比是在大约 1 秒的时间窗口内评估的。

基于 delay-based controller 与 loss-based controller 合作，并查看 数据包到达时间。这个基于延迟的控制器旨在识别网络链接何时变为 日益拥塞，甚至可能在数据包丢失发生之前降低带宽估计。这 理论上，路径上最繁忙的网络接口将继续对数据包进行排队 直到接口的缓冲区容量用完。如果该接口继续接收 如果流量超过它能够发送的流量，它将被迫丢弃所有无法容纳的数据包 它的缓冲区空间。这种类型的数据包丢失对于低延迟/实时尤其具有破坏性 通信，但它也会降低通过该链路进行的所有通信的吞吐量，并且应该 理想情况下避免使用。因此，GCC 会尝试弄清楚网络链接是否越来越大 队列*深度。*如果它观察到，它将减少带宽使用 排队延迟随时间推移而增加。

为了实现这一点，GCC 尝试通过测量 round 中的细微增加来推断队列深度的增加 行程时间。它记录帧的 “inter-arrival time”，：到达时间的差异 的两组数据包（通常是连续的视频帧）。这些数据包经常分组 以固定的时间间隔出发（例如，对于 24 fps 的视频，每 1/24 秒一次）。因此， 然后，测量到达间隔时间就像记录 第一个数据包组（即帧）和下一个数据包组的第一帧。`t(i) - t(i-1)`

在下图中，数据包间延迟增加的中位数为 +20 毫秒，这是一个明显的指标 网络拥塞。

![](https://webrtcforthecurious.com/docs/images/06-twcc.png)

如果到达间隔时间随时间增加，则假定队列深度增加 连接网络接口，并被视为网络拥塞。（注意：GCC 足够聪明 控制这些测量值以了解帧字节大小的波动。GCC 优化其延迟 使用[卡尔曼滤波器](https://en.wikipedia.org/wiki/Kalman_filter)进行测量，并需要许多 在标记拥塞之前测量网络往返时间（及其变化）。一罐 将 GCC 的卡尔曼滤波器视为取代线性回归：有助于使准确 即使抖动将噪声添加到 timing measurements 中。标记拥塞后，GCC 将降低可用比特率。或者，在稳定的网络条件下，它可以缓慢地 增加其带宽估计值以测试更高的负载值。

### TMMBR、TMMBN 和 REMB[#](https://webrtcforthecurious.com/docs/06-media-communication/#tmmbr-tmmbn-and-remb)

对于 TMMBR/TMMBN 和 REMB，接收方首先估计可用的入站带宽（使用 协议（如 GCC），然后将这些带宽估计值传达给远程发件人。他们 不需要交换有关数据包丢失或有关网络拥塞的其他性质的详细信息 因为在接收方作允许他们测量到达间隔时间和数据包丢失 径直。相反，TMMBR、TMMBN 和 REMB 仅交换带宽估计值本身：

- **临时最大媒体流比特率请求** - 请求的比特率的尾数/指数 对于单个 SSRC。
- **临时最大媒体流比特率通知** - 通知 TMMBR 具有的消息 被接收。
- **接收方估计的最大比特率** - 请求的比特率的尾数/指数 整个会话。

TMMBR 和 TMMBN 首先出现，并在 [RFC 5104](https://tools.ietf.org/html/rfc5104) 中定义。雷姆布 后来，在 [draft-alvestrand-rmcat-remb](https://tools.ietf.org/html/draft-alvestrand-rmcat-remb-03) 中提交了一份草案，但它 从未标准化。

使用 REMB 的示例会话可能如下所示：

![](https://webrtcforthecurious.com/docs/images/06-remb.png)

这种方法在纸上效果很好。发送方接收接收方的估算值，将编码器比特率设置为接收到的值。多田！我们已经根据网络条件进行了调整。

然而，在实践中，REMB 方法存在多个缺点。

编码器效率低下是第一个问题。当您为编码器设置比特率时，它不一定 输出您请求的确切比特率。编码可能会输出更多或更少的位，具体取决于 编码器设置和正在编码的帧。

例如，将 x264 编码器与 一起使用可能会明显偏离指定的目标比特率。下面是一个可能的情况：`tune=zerolatency`

- 假设我们首先将比特率设置为 1000 kbps。
- 编码器仅输出 700 kbps，因为没有足够的高频特征进行编码。（又名 - “盯着一堵墙”。
- 我们还假设接收方以零丢包率获得 700 kbps 视频。然后，它应用 REMB 规则 1 将传入比特率提高 8%。
- 接收方向发送方发送建议为 756 kbps （700 kbps * 1.08） 的 REMB 数据包。
- 发送方将编码器比特率设置为 756 kbps。
- 编码器输出的比特率更低。
- 这个过程继续重复，将比特率降低到绝对最低。

您可以看到这将如何导致繁重的编码器参数调整，即使在连接良好的情况下，也会导致无法观看的视频让用户感到惊讶。

### 全程交通拥堵控制[#](https://webrtcforthecurious.com/docs/06-media-communication/#transport-wide-congestion-control)

传输范围拥塞控制是 RTCP 网络状态的最新发展 通信。它在 [draft-holmer-rmcat-transport-wide-cc-extensions-01](https://datatracker.ietf.org/doc/html/draft-holmer-rmcat-transport-wide-cc-extensions-01) 中定义， 但也从未被标准化。

TWCC 使用了一个非常简单的原理：

![](https://webrtcforthecurious.com/docs/images/06-twcc-idea.png)

使用 REMB 时，接收方会以可用的下载比特率指示发送方。它使用 关于推断的数据包丢失和仅具有关于数据包间到达的数据的精确测量 时间。

TWCC 几乎是 SR/RR 和 REMB 代协议之间的混合方法。它带来了 带宽估计返回到发送方（类似于 SR/RR），但其带宽估计技术 更类似于 REMB 一代。

使用 TWCC，接收方让发送方知道每个数据包的到达时间。这就足够了 发送方测量数据包间到达延迟变化以及识别 哪些数据包被丢弃或到达太晚，无法对音频/视频源做出贡献。使用此数据 由于频繁交换，发件人能够快速适应不断变化的网络条件，并且 使用 GCC 等算法改变其输出带宽。

发送方跟踪发送的数据包、序列号、大小和时间戳。当 sender 从接收方接收 RTCP 消息，它将发送数据包间延迟与 接收延迟。如果接收延迟增加，则表示网络拥塞，发送方 必须采取纠正措施。

通过向发件人提供原始数据，TWCC 提供了对实时网络的极好视图 条件：

- 几乎即时的数据包丢失行为，包括单个丢失的数据包
- 准确的发送比特率
- 准确的接收比特率
- 抖动测量
- 发送和接收数据包延迟之间的差异
- 网络如何容忍突发或稳定带宽传输的说明

TWCC 最重要的贡献之一是它为 WebRTC 提供了灵活性 开发 人员。通过将拥塞控制算法整合到发送端，它允许简单的 客户端代码可以广泛使用，并且随着时间的推移需要最少的增强。综合体 然后，拥塞控制算法可以直接在硬件上更快地迭代 控制（如第 8 节中讨论的选择性转发单元）。对于浏览器和 移动设备，这意味着这些客户端可以从算法增强功能中受益，而无需 等待标准化或浏览器更新（这可能需要相当长的时间才能广泛使用）。

## 带宽估计替代方案[#](https://webrtcforthecurious.com/docs/06-media-communication/#bandwidth-estimation-alternatives)

部署最多的实现是“A Google Congestion Control Algorithm for Real-Time 通信“在 [draft-alvestrand-rmcat-congestion](https://tools.ietf.org/html/draft-alvestrand-rmcat-congestion-02) 中定义。

GCC 有几种替代方案，例如 [NADA：统一拥塞控制方案 Real-Time Media](https://tools.ietf.org/html/draft-zhu-rmcat-nada-04) 和 [SCReAM - 自时钟 多媒体的速率适应](https://tools.ietf.org/html/draft-johansson-rmcat-scream-cc-05)。
