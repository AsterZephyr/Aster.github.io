---
title: "WebRTC的uFrag（用户名片段）和 uPwd（密码）"
date: 2025-07-03T03:51:30Z
draft: false
tags: ["技术笔记"]
author: "Aster"
description: "Created: 2025年3月7日 20:44..."
---

# WebRTC的uFrag（用户名片段）和 uPwd（密码）

Created: 2025年3月7日 20:44
Status: 完成

在 WebRTC 中，信令过程中的 `uFrag`（用户名片段）和 `uPwd`（密码）是 ICE（Interactive Connectivity Establishment）协议的核心参数，用于验证候选者（Candidate）的合法性，确保通信双方的身份安全。以下是具体说明：

### **uFrag 和 uPwd 的作用**

1. **身份验证与防篡改**
    - `uFrag` 和 `uPwd` 是 ICE 协议中用于生成 **消息完整性校验值（HMAC）** 的凭证。
    - 在 ICE 候选者交换过程中，双方通过这两个值生成哈希值，验证候选者信息的完整性和来源合法性，防止中间人攻击   。
2. **ICE 流程的必需参数**
    - ICE 候选者（如本地 IP、NAT 映射地址、中继地址）通过信令通道交换时，必须附带 `uFrag` 和 `uPwd`。
    - 连接检查（STUN Binding Request/Response）时，客户端需携带由 `uFrag` 和 `uPwd` 生成的校验信息，否则对方会拒绝连接   。

### **SDP 中的表示形式**

在 SDP 协议中，`uFrag` 和 `uPwd` 通过以下属性行定义：

```
Sdp
a=ice-ufrag:<随机生成的字符串>  // 用户名片段（通常为 4-256 字符）
a=ice-pwd:<随机生成的字符串>   // 密码（通常为 22-256 字符）

```

**示例**：

```
Sdp
a=ice-ufrag:7s9D
a=ice-pwd:j5bQmZzKq9Xp3L2WvYr6tG

```

**规则**：

- 每个媒体流（如音频、视频）的 SDP 媒体描述（`m=` 行）中必须包含独立的 `ice-ufrag` 和 `ice-pwd`。
- 若未显式定义，WebRTC 会自动生成这两个值

### **工作流程中的具体应用**

1. **候选者交换阶段**
    - 发起方（Offer）和接收方（Answer）通过信令服务器交换 SDP，其中包含各自的 `ice-ufrag` 和 `ice-pwd`。
    - 例如，发起方的 SDP 包含 `a=ice-ufrag:abcd` 和 `a=ice-pwd:1234`，接收方则回复自己的对应值
2. **连接检查阶段**
    - 双方根据候选者列表发送 STUN 请求，请求头部的 `USERNAME` 字段由 `uFrag` 拼接对方 `uFrag` 生成（如 `发起方uFrag:接收方uFrag`）。
    - STUN 消息的校验值（MESSAGE-INTEGRITY）通过 `uPwd` 计算，确保未被篡改  。

### **安全性与实现要求**

1. **随机性与唯一性**
    - `uFrag` 和 `uPwd` 必须由强随机算法生成，且每次会话唯一，避免重放攻击。
    - WebRTC 内部自动管理这两个值的生成和更新 。
2. **与 DTLS 证书的关联**
    - ICE 验证完成后，双方通过 DTLS 协议建立加密信道，证书指纹（`a=fingerprint`）会进一步验证身份，与 `uFrag/uPwd` 形成双重安全保障  。
