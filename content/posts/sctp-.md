---
title: "SCTP（流控制传输协议）关联状态图"
date: 2025-07-03T03:51:30Z
draft: false
tags: ["技术笔记"]
author: "Aster"
description: "Created: 2025年3月10日 17:30..."
---

# SCTP（流控制传输协议）关联状态图

Created: 2025年3月10日 17:30
Status: 完成

![SCTP系列关联状态图.png](SCTP%EF%BC%88%E6%B5%81%E6%8E%A7%E5%88%B6%E4%BC%A0%E8%BE%93%E5%8D%8F%E8%AE%AE%EF%BC%89%E5%85%B3%E8%81%94%E7%8A%B6%E6%80%81%E5%9B%BE%201b24bf1cd99880819ca2db5f9b2815da/SCTP%E7%B3%BB%E5%88%97%E5%85%B3%E8%81%94%E7%8A%B6%E6%80%81%E5%9B%BE.png)

- **绿色路径**：正常连接建立与关闭。
- **红色路径**：异常终止（如超时或 `ABORT`）。
- **橙色虚线**：定时器触发的重传或状态回退。

**SCTP（流控制传输协议）关联状态图**的详细解释，分状态和转移逻辑说明：

### **1. 初始状态：CLOSED**

- **含义**：未建立关联或关联已终止。
- **触发事件**：
    - **收到 INIT 消息**：启动关联建立流程，生成 Cookie，发送 **INIT ACK**，进入 **COOKIE-WAIT** 状态。
    - **收到 ABORT 消息**：直接删除传输控制块（TCB），保持 **CLOSED**。

### **2. 关联建立阶段**

### **状态1：COOKIE-WAIT**

- **含义**：等待对端返回 **COOKIE ECHO**。
- **触发事件**：
    - **发送 INIT ACK 后**：启动初始化定时器（等待对端响应）。
    - **收到有效的 COOKIE ECHO**（携带正确 Cookie）：
        - 创建 TCB，发送 **COOKIE ACK**，进入 **ESTABLISHED**（关联建立成功）。
    - **初始化定时器超时**：回到 **CLOSED**。

### **状态2：COOKIE-ECHOED**

- **含义**：已发送 **COOKIE ECHO**，等待对端确认。
- **触发事件**：
    - **收到 COOKIE ACK**：停止 Cookie 定时器，进入 **ESTABLISHED**。
    - **Cookie 定时器超时**：回到 **CLOSED**。

### **3. 关联已建立：ESTABLISHED**

- **含义**：SCTP 关联成功建立，可正常传输数据块（DATA chunks）。
- **触发事件**：
    - **主动发起关闭**（发送 SHUTDOWN）：进入 **SHUTDOWN-PENDING**，检查未完成数据块。
    - **收到 SHUTDOWN 消息**：进入 **SHUTDOWN-RECEIVED**，检查未完成数据块。

### **4. 关联终止阶段**

### **状态3：SHUTDOWN-PENDING**

- **含义**：等待未完成数据块处理完毕，准备发送 **SHUTDOWN**。
- **触发事件**：
    - **无未完成数据块**：发送 **SHUTDOWN**，启动关闭定时器，进入 **SHUTDOWN-SENT**。

### **状态4：SHUTDOWN-SENT**

- **含义**：已发送 **SHUTDOWN**，等待对端确认。
- **触发事件**：
    - **收到 SHUTDOWN ACK**：
        - 发送 **SHUTDOWN COMPLETE**，删除 TCB，回到 **CLOSED**。
    - **关闭定时器超时**：重传 **SHUTDOWN**。

### **状态5：SHUTDOWN-RECEIVED**

- **含义**：收到对端 **SHUTDOWN**，需确认处理。
- **触发事件**：
    - **无未完成数据块**：发送 **SHUTDOWN ACK**，启动关闭定时器，进入 **SHUTDOWN-ACK-SENT**。

### **状态6：SHUTDOWN-ACK-SENT**

- **含义**：已发送 **SHUTDOWN ACK**，等待最终确认。
- **触发事件**：
    - **收到 SHUTDOWN COMPLETE**：删除 TCB，回到 **CLOSED**。
    - **关闭定时器超时**：重传 **SHUTDOWN ACK**。

### **5. 异常终止**

- **触发事件**：
    - **收到 ABORT 消息**：立即终止关联，删除 TCB，回到 **CLOSED**。
    - **主动发送 ABORT**：直接删除 TCB，回到 **CLOSED**。

### **关键机制**

1. **Cookie 验证**：防止拒绝服务攻击（DoS），确保关联请求合法。
2. **四次握手**（INIT → INIT ACK → COOKIE ECHO → COOKIE ACK）：比 TCP 三次握手更安全。
3. **优雅关闭**（Graceful Shutdown）：确保所有数据块传输完毕后再终止关联。
4. **定时器管理**：处理网络延迟或丢包，避免无限等待。

### **与 TCP 状态机对比**

| **状态** | **SCTP 行为** | **TCP 等效状态** |
| --- | --- | --- |
| `CLOSED` | 初始或终止状态 | `CLOSED` |
| `COOKIE-WAIT` | 等待对端返回 Cookie | `SYN-SENT` |
| `ESTABLISHED` | 数据正常传输 | `ESTABLISHED` |
| `SHUTDOWN-PENDING` | 等待未完成数据处理 | `FIN-WAIT-1` |
| `SHUTDOWN-SENT` | 已发送关闭请求，等待确认 | `FIN-WAIT-2` |

### **应用场景**

- **实时通信**：WebRTC 使用 SCTP 传输 DataChannel 数据。
- **容错传输**：多宿主支持（Multi-homing）提升网络可靠性。
- **信令协议**：如 SIGTRAN（SS7 over IP）。
