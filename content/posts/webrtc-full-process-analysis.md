---
title: "WebRTC底层全流程解析：从0到1建立实时通信的关键步骤与协议协同"
date: 2025-03-07T20:54:00Z
draft: false
tags: ["WebRTC", "实时通信", "网络协议", "音视频"]
author: "Aster"
description: "深入解析WebRTC实时通信的完整建立流程，从设备检测到媒体传输的每个关键步骤"
---

WebRTC的通信建立过程涉及**信令协商、网络穿透、媒体传输、安全加密**等多个环节，其底层协议协同工作类似于HTTP通信中的DNS解析、TCP握手、TLS加密等流程。以下是分步骤解析：

## 阶段1：设备检测与权限获取

**核心协议/API**：`getUserMedia`、`MediaStream`

**作用**：
1. 调用`navigator.mediaDevices.getUserMedia`检测摄像头/麦克风是否存在，请求用户授权。
2. 采集原始音视频数据（PCM音频/YUV视频），封装为`MediaStream`对象。

**建立方式**：
- 浏览器通过操作系统API访问硬件设备
- 实时捕获音视频流，建立本地媒体源

## 阶段2：创建PeerConnection对象

**核心协议/API**：`RTCPeerConnection`

**作用**：
- 创建点对点连接的核心对象
- 配置STUN/TURN服务器用于NAT穿透
- 管理整个WebRTC连接的生命周期

## 阶段3：信令协商(SDP交换)

**核心协议**：SDP (Session Description Protocol)

**详细流程**：

### 3.1 创建Offer
- **发起方**调用`createOffer()`生成SDP Offer
- SDP包含：支持的编解码器、网络信息、媒体能力等
- 调用`setLocalDescription(offer)`设置本地描述

### 3.2 传输Offer
- 通过信令服务器(WebSocket/Socket.io)将SDP Offer发送给接收方
- 信令服务器只负责中转，不参与媒体传输

### 3.3 创建Answer
- **接收方**收到Offer后调用`setRemoteDescription(offer)`
- 调用`createAnswer()`生成SDP Answer
- 调用`setLocalDescription(answer)`设置本地描述

### 3.4 传输Answer
- 将SDP Answer通过信令服务器发送回发起方
- 发起方调用`setRemoteDescription(answer)`完成SDP协商

## 阶段4：ICE候选交换与网络穿透

**核心协议**：ICE (Interactive Connectivity Establishment)

### 4.1 ICE候选收集
每当PeerConnection收集到新的网络路径时：
- 触发`onicecandidate`事件
- 生成ICE候选（包含IP地址、端口、协议类型等）
- 通过信令服务器交换ICE候选

### 4.2 网络连通性检测
**涉及协议**：
- **STUN** (Session Traversal Utilities for NAT)：获取公网IP和端口
- **TURN** (Traversal Using Relays around NAT)：在无法直连时提供中继服务
- **ICE**：测试各种网络路径的连通性

### 4.3 最优路径选取
- 测试所有可能的连接路径（直连、STUN、TURN）
- 选择延迟最低、带宽最高的路径
- 建立UDP连接用于媒体传输

## 阶段5：DTLS握手与加密建立

**核心协议**：DTLS (Datagram Transport Layer Security)

**作用**：
- 在UDP之上建立加密通道
- 交换加密密钥，确保媒体数据安全传输
- 验证通信双方身份

## 阶段6：媒体传输

**核心协议**：
- **RTP** (Real-time Transport Protocol)：实时传输音视频数据
- **RTCP** (RTP Control Protocol)：传输质量控制和统计信息
- **SRTP** (Secure RTP)：加密的RTP传输

### 媒体处理流程：
1. **编码**：原始音视频数据编码(H.264/VP8/VP9视频，Opus/G.711音频)
2. **打包**：封装成RTP包，添加时间戳、序列号等
3. **加密**：使用SRTP加密
4. **传输**：通过已建立的UDP连接发送
5. **接收处理**：解密→解包→解码→播放

## 阶段7：连接维护与监控

**功能**：
- **心跳检测**：定期发送RTCP包维持连接
- **网络质量监控**：监测丢包率、延迟、带宽等
- **自适应码率**：根据网络状况动态调整编码参数
- **连接重连**：网络变化时重新进行ICE协商

## 完整时序图

```
客户端A              信令服务器              客户端B
   |                    |                    |
   |-- getUserMedia --> |                    |
   |                    |                    |
   |-- createOffer ----> |                    |
   |                    |---- SDP Offer ---> |
   |                    |                    |-- setRemoteDescription
   |                    |                    |-- createAnswer
   |                    |<--- SDP Answer --- |
   |-- setRemoteDescription                  |
   |                    |                    |
   |-- ICE Candidates > |---- ICE Cand. --> |
   |<-- ICE Candidates - |<--- ICE Cand. --- |
   |                    |                    |
   |<========== DTLS握手 + 媒体传输 ========> |
```

## 关键技术要点

1. **信令**：仅用于初始协商，媒体数据点对点传输
2. **NAT穿透**：通过STUN/TURN实现，ICE协议自动选择最优路径  
3. **安全性**：DTLS加密确保端到端安全
4. **实时性**：UDP传输，牺牲可靠性换取低延迟
5. **自适应**：根据网络状况动态调整传输策略

这个流程确保了WebRTC能够在复杂网络环境下建立高质量的实时音视频通信。