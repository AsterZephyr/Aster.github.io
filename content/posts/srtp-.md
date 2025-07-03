---
title: "SRTP密钥协商流程"
date: 2025-07-03T03:51:30Z
draft: false
tags: ["技术笔记"]
author: "Aster"
description: "Created: 2025年3月10日 15:31..."
---

# SRTP密钥协商流程

Created: 2025年3月10日 15:31
Status: 完成

### **1. SDP 交换与角色协商** 【图1：SDP交换流程】

- **`a=setup`**：协商 DTLS 角色（Client/Server），通过 `active/passive/actpass` 确定握手发起方。
    - 示例：`a=setup:active` 表示本端作为 DTLS Client 主动发起握手。
- **`a=fingerprint`**：交换自签名证书的 SHA-256 哈希值，用于身份验证（RFC4572）。
    - 示例：`a=fingerprint:sha-256 49:66:12:17:0D:1C...`。

### **2. DTLS 握手** 【图2：DTLS握手流程】

- **ClientHello/ServerHello**：
    - **版本**：协商 DTLS 版本（如 DTLS 1.2）。
    - **加密套件**：选择算法（如 `TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256`）。
    - **扩展协议**：启用 `use_srtp` 扩展（RFC5764），声明 SRTP 配置（如 `SRTP_AES128_CM_HMAC_SHA1_80`）。
- **证书验证**：比对 SDP 中的指纹与 DTLS 证书哈希，防止中间人攻击。

### **3. 密钥交换（ECDHE）** 【图3：ECDHE密钥交换】

- **Server/Client Key Exchange**：交换椭圆曲线公钥（`Spk` 和 `Cpk`）。
    - 基于 ECDH 算法，双方计算共享密钥 `pre_master_secret`。
    - 公式：`S = Ds * Cpk = Dc * Spk`（`Ds` 和 `Dc` 为私钥）。

### **4. 主密钥与 SRTP 密钥导出** 【图4：密钥派生流程】

- **计算 `master_secret`**：
    
    ```python
    Python
    master_secret = PRF(pre_master_secret, "master secret", client_random + server_random)[0:48]
    
    ```
    
- **生成 SRTP 密钥块**：
    
    ```python
    Python
    key_block = PRF(master_secret, "EXTRACTOR-dtls_srtp", client_random + server_random)[0:60]
    
    ```
    
    - **分割密钥块**：
        - `client_write_key`（16B） + `server_write_key`（16B）
        - `client_salt`（14B） + `server_salt`（14B）。

### **5. SRTP 加密初始化** 【图5：SRTP加密流程】

- **配置 SRTP 会话**：
    - 使用 `client_write_key + client_salt` 加密发送数据。
    - 使用 `server_write_key + server_salt` 解密接收数据。
- **加密媒体流**：通过 AES-CM 加密 RTP 包，HMAC-SHA1 验证完整性。
