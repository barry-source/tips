# HTTPS 工作流程

## 一、URI / URL / URN

URI 是统一资源标识符，是 URL 和 URN 的超集（URL 和 URN 是 URI 的子集，理论上两者不相交，实际中存在交集）。

| 名称 | 全称 | 说明 |
| --- | --- | --- |
| URI | Uniform Resource Identifier | 统一资源标识符，用于标识某一互联网资源 |
| URL | Uniform Resource Locator | 统一资源定位符，表示资源的地址 |
| URN | Uniform Resource Name | 统一资源名称，通过名字来标识资源 |

### URI 的格式

```
scheme://[userinfo@]host[:port][/path][?query][#fragment]
```

- **scheme**：方案名 / 协议名，表示资源使用哪种协议访问（http、https、ftp 等）
- **authority**：权限信息，包含 `userinfo`（用户信息，可选）、`host`（主机名）和 `port`（端口号，可选）
- **path**：路径，标记资源所在的位置
- **query**：查询字符串，对资源附加的额外要求
- **fragment**：片段标识符，指向资源内部的某一部分

> 在 URI 中，`@ & /` 等特殊字符和汉字必须进行编码（Percent-encoding），否则服务器收到 HTTP 报文后无法正确处理。

---

## 二、HTTP 状态码

状态码位于响应报文中，表示服务器对请求的处理结果。状态码后的原因短语是简单的文字描述，可以自定义。状态码是十进制的三位数，分为五类：

| 分类 | 含义 | 常见状态码 |
| --- | --- | --- |
| 1xx | 信息性状态码，表示请求已接收，继续处理 | 100 Continue、101 Switching Protocols |
| 2xx | 成功，请求已被成功接收并处理 | 200 OK、204 No Content、206 Partial Content（断点续传） |
| 3xx | 重定向，需要进一步操作以完成请求 | 301 永久重定向、302 临时重定向、304 Not Modified（缓存重定向） |
| 4xx | 客户端错误，请求有语法错误或无法完成 | 400 Bad Request、403 Forbidden、404 Not Found |
| 5xx | 服务器错误，服务器在处理请求时发生错误 | 500 Internal Server Error、501 Not Implemented、502 Bad Gateway、503 Service Unavailable、504 Gateway Timeout |

---

## 三、HTTP 特点

- **灵活可扩展**：可以任意添加头字段实现任意功能；
- **可靠传输**：基于 TCP/IP 协议，"尽量"保证数据的送达（可靠性由 TCP 保证，而非 HTTP 本身）；
- **应用层协议**：比 FTP、SSH 等更通用、功能更多，能够传输任意数据；
- **请求 - 应答模式**：客户端主动发起请求，服务器被动回复；
- **无状态**：每个请求都是互相独立、毫无关联的，协议本身不要求客户端或服务器记录请求相关的信息。

---

## 四、HTTP 优缺点（HTTP/1.1）

### 优点

- 简单、灵活、易于扩展；
- 拥有成熟的软硬件环境，应用非常广泛，是互联网的基础设施；
- 无状态，可以轻松实现集群化，扩展性能（需要"有状态"时可用 Cookie / Session 技术）。

### 缺点

- **明文传输**：数据完全可见，能够方便地研究分析，但也容易被窃听；
- **不安全**：无法验证通信双方的身份，也不能判断报文是否被篡改；
- **性能有限**：不完全适应现在的互联网，HTTP/1.1 存在队头阻塞等问题，还有很大提升空间。

> 参考文章：[Keyless SSL: The Nitty Gritty Technical Details](https://blog.cloudflare.com/keyless-ssl-the-nitty-gritty-technical-details/)

---

## 五、加密基础

HTTPS 的安全性建立在以下加密技术之上：

### 1. 对称加密

加密和解密使用**同一个密钥**。

- 优点：速度快，适合大量数据加密；
- 缺点：密钥分发困难，双方必须事先共享密钥。

常见算法：AES、ChaCha20、DES（已不安全）。

### 2. 非对称加密

加密和解密使用**一对密钥**（公钥和私钥），公钥可以公开，私钥必须保密。

- 用公钥加密的数据只能用私钥解密；
- 用私钥签名的数据可以用公钥验证。

- 优点：解决了密钥分发问题，可实现身份认证；
- 缺点：计算速度慢，不适合大量数据加密。

常见算法：RSA、ECC（椭圆曲线加密）。

### 3. 哈希算法

将任意长度的数据映射为固定长度的摘要，具有不可逆性。

常见算法：SHA-256、SHA-384、MD5（已不安全）。

### 4. HTTPS 的组合策略

HTTPS 采用**混合加密**机制：

1. 握手阶段使用**非对称加密**来协商出对称密钥（Session Key）；
2. 通信阶段使用**对称加密**来加密实际传输的数据；
3. 使用**哈希算法**生成 MAC（消息认证码）或使用 AEAD 保证数据完整性。

---

## 六、SSL 与 TLS 的区别

### 概述

SSL（Secure Sockets Layer，安全套接字层）和 TLS（Transport Layer Security，传输层安全性）都是用于在网络上的两个设备之间创建加密安全连接的通信协议。TLS 是 SSL 的升级版本，用于修复 SSL 的已知安全漏洞。

| 维度 | SSL | TLS |
|------|-----|-----|
| **全称** | Secure Sockets Layer（安全套接字层） | Transport Layer Security（传输层安全性） |
| **版本历史** | SSL 1.0（未公开）、2.0（1995）、3.0（1996） | TLS 1.0（1999，相当于 SSL 3.1）、1.1（2006）、1.2（2008）、1.3（2018） |
| **当前状态** | ❌ 所有版本均已弃用 | ✅ TLS 1.2 和 1.3 处于活跃使用状态 |
| **警报消息** | 仅警告和致命两种，未加密 | 增加关闭通知类型，已加密 |
| **消息认证** | 使用 MAC（MD5 算法，已过时） | 使用 HMAC（更安全的哈希认证） |
| **密码套件** | 支持有已知安全漏洞的早期算法 | 使用高级加密算法 |
| **握手** | 复杂且缓慢，步骤多 | 步骤更少，连接更快（TLS 1.3 仅 1-RTT，即一次往返时间） |

### 详细对比

#### 1. 握手过程

- **SSL 握手**：显式连接，步骤比 TLS 多
- **TLS 握手**：隐式连接，通过减少其他步骤和密码套件总数加快流程

#### 2. 警报消息

- **SSL**：只有两种警报消息类型——警告（Warning）和致命（Fatal），且消息未加密
- **TLS**：增加了关闭通知（Close Notify）类型，表示会话正常结束。TLS 警报消息经过加密，安全性更高

#### 3. 消息身份认证

- **SSL**：使用 MAC（消息认证码），基于 MD5 算法生成
- **TLS**：使用 HMAC（基于哈希的消息认证码），加密和安全性更强

#### 4. 密码套件

TLS 中的密码套件算法是从 SSL 升级而来的，移除了已知不安全的算法，使用更高级的加密算法。

#### 5. 版本弃用时间线

```
1995  SSL 2.0 发布
1996  SSL 3.0 发布
1999  TLS 1.0 发布（相当于 SSL 3.1）
2006  TLS 1.1 发布
2008  TLS 1.2 发布
2011  SSL 2.0 被 RFC 6176 正式弃用
2015  SSL 3.0 因 POODLE 攻击被 RFC 7568 正式弃用
2018  TLS 1.3 发布
2021  TLS 1.0 和 TLS 1.1 被正式弃用
2023  AWS 等云服务要求客户端必须支持 TLS 1.2 或更高版本
```

### 术语说明

目前业界仍常用 "SSL" 来指代 TLS 证书，但严格来说：

- 所有 SSL 版本均已弃用
- TLS 证书是行业标准
- 大多数标记为 "SSL 证书" 的证书实际已同时支持 SSL 和 TLS 协议
- 证书和协议不是一回事，应确保服务器配置支持 TLS 1.2+，而非 SSL

---

## 七、HTTPS 名词解释

| 名称 | 说明 |
| --- | --- |
| **Session Key** | 握手结束时生成的对称加密密钥，用于加密服务器和客户端之间的通信数据 |
| **Client Random** | 客户端生成的 32 字节随机数（TLS 1.2 中前 4 字节为时间戳，后 28 字节为随机数；TLS 1.3 中全部为随机数） |
| **Server Random** | 服务器生成的 32 字节随机数，格式同上 |
| **Pre-master Secret** | 48 字节的预主密钥，与 Client Random、Server Random 一起通过伪随机函数（PRF）生成 Session Key |
| **Cipher Suite** | 加密套件，唯一标识 TLS 连接所使用的一组算法，包含以下四个部分：<br>• **密钥交换**（Key Exchange）：RSA / DHE / ECDHE<br>• **身份认证**（Authentication）：RSA / ECDSA<br>• **对称加密**（加密 / 解密）：AES / ChaCha20<br>• **消息认证**（完整性校验）：SHA-256 / SHA-384 / AEAD |

---

## 八、RSA 握手流程（TLS 1.2）

![RSA 握手流程](https://upload-images.jianshu.io/upload_images/1846524-6c9abb7f17c308fa.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

### 第 1 步：Client → Server（ClientHello）

客户端发送消息给服务器，包含：

- 客户端生成的随机数（**Client Random**）
- 客户端支持的加密算法列表（Cipher Suites）
- 客户端支持的 TLS/SSL 协议版本
- 其他握手信息

### 第 2 步：Server → Client（ServerHello + Certificate）`涉及证书、RSA`

服务器接收消息后，回应客户端，包含：

- 服务器生成的随机数（**Server Random**）
- 从客户端列表中选取的加密算法套件
- 服务器的数字证书（包含**公钥**、域名、证书颁发机构、有效期等）

### 第 3 步：密钥交换与验证 `涉及对称加密`

1. **验证证书合法性**：客户端校验证书是否由受信任的 CA 签发、是否过期、域名是否匹配等；
2. 如果合法，客户端生成一个 **Pre-master Secret**（48 字节随机数）；
3. 用服务器证书中的**公钥**加密 Pre-master Secret，发送给服务器；
4. 服务器用**私钥解密**，取出 Pre-master Secret；
5. 此时双方都拥有 Client Random、Server Random、Pre-master Secret，通过 PRF 计算出相同的 **Session Key**；
6. 双方各发送一段加密信息验证密钥是否一致，握手结束。

> 后续的通信数据都使用 Session Key 进行对称加密。

### RSA 握手的缺点

RSA 握手**不具备前向安全性（Forward Secrecy）**：如果服务器的私钥泄漏，且攻击者记录了之前的握手过程和通信数据，就可以解密出 Pre-master Secret，进而推算出 Session Key，还原所有历史通信。

---

## 九、DH 握手流程（TLS 1.2）

DH（Diffie-Hellman）握手解决了 RSA 握手缺乏前向安全性的问题。它采用两个不同的机制：

1. **创建共享的 Pre-master Secret**：利用 DH 算法，双方各自生成密钥参数并交换，最终独立计算出相同的共享密钥；
2. **服务器认证**：利用数字签名（RSA / ECDSA）对发送的参数进行签名，确保参数未被篡改。

### DH 算法原理

DH 算法基于**离散对数问题**的难解性：在有限域中，已知 g、p、g^a mod p，求 a 是极其困难的。双方交换 g^a mod p 和 g^b mod p 后，各自可以计算出 g^(ab) mod p 作为共享密钥，而窃听者无法推算。

ECDHE（椭圆曲线 DH 临时密钥交换）是 DH 的椭圆曲线变体，安全性更高、速度更快。

![DH 握手流程](https://upload-images.jianshu.io/upload_images/1846524-cbc80f6490f9aff0.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

### 第 1 步：Client → Server（ClientHello）

客户端发送消息给服务器，包含：

- 客户端支持的 SSL/TLS 协议版本
- 客户端生成的随机数（**Client Random**）
- 客户端支持的加密算法列表
- 其他握手信息

### 第 2 步：Server → Client（ServerHello + Certificate + ServerKeyExchange）

服务器回应客户端，包含：

- 服务器生成的随机数（**Server Random**）
- 选取的加密算法套件（包含 ECDHE）
- 服务器的数字证书（包含公钥、域名、证书颁发机构等）
- **Server Key Exchange**：服务器生成 DH 参数，用**私钥对参数签名**后发送给客户端，防止参数被篡改

### 第 3 步：Server → Client（ServerHelloDone）

服务器发送 ServerHelloDone，表示服务器端的握手消息发送完毕。

### 第 4 步：Client → Server（验证 + ClientKeyExchange）

1. **验证证书合法性**：校验证书是否由受信任的 CA 签发、是否过期、域名是否匹配等；
2. **验证签名**：用证书中的公钥验证服务器发送的 DH 参数签名，确保参数未被篡改；
3. 如果验证通过，客户端生成自己的 DH 参数，发送给服务器（**Client Key Exchange**）；
4. 此时双方利用 DH 算法各自计算出相同的 **Pre-master Secret**；
5. 结合 Client Random、Server Random、Pre-master Secret，通过 PRF 计算出 **Session Key**；
6. 双方各发送一段加密信息验证密钥是否一致，握手结束。

### 完整性保护

在以上流程中，应用层发送数据时会附加 **MAC（消息认证码）** 报文摘要，MAC 能够检测报文是否遭到篡改。（TLS 1.3 中使用 AEAD 替代了独立的 MAC。）

### RSA 握手 vs DH 握手

| 对比项 | RSA 握手 | DH 握手（ECDHE） |
| --- | --- | --- |
| 密钥交换算法 | RSA | DH / ECDHE |
| 身份认证 | RSA（公钥加密 Pre-master） | RSA / ECDSA（数字签名） |
| 前向安全性 | ❌ 不具备 | ✅ 具备 |
| 性能 | 较快 | 略慢（DH 计算开销大，ECDHE 已优化） |

---

## 十、TLS 1.3 握手流程

TLS 1.3（RFC 8446，2018 年发布）对握手流程进行了大幅简化，从 TLS 1.2 的 2-RTT 减少到 **1-RTT**，并支持 **0-RTT**（早期数据）。

### TLS 1.3 的主要改进

| 改进项 | TLS 1.2 | TLS 1.3 |
|--------|---------|---------|
| **RTT 数** | 2-RTT（RSA 和 DH 都需要 2 次往返） | 1-RTT（完整握手），0-RTT（会话恢复） |
| **密钥交换算法** | 支持 RSA、DH、ECDHE | **仅保留 ECDHE**（移除了无前向安全性的算法） |
| **握手消息** | 部分明文，部分加密 | ServerHello **之后所有消息加密** |
| **密码套件** | 大量套件组合（数百种） | 仅 5 种 AEAD 套件 |
| **MAC 机制** | 独立的 HMAC | 统一使用 **AEAD**（AES-GCM / ChaCha20-Poly1305） |
| **会话恢复** | Session ID / Session Ticket（有延迟） | PSK（预共享密钥），可实现 0-RTT |
| **前向安全性** | RSA 不具备，DHE/ECDHE 具备 | **所有套件都具备** |

### ECDHE 算法原理

TLS 1.3 仅使用 **ECDHE**（椭圆曲线 Diffie-Hellman 临时密钥交换）：

```
椭圆曲线 DH（ECDHE）：
  
  选择椭圆曲线（如 X25519 或 P-256）
  
  客户端：生成随机数 a，计算 A = a × G（G 是椭圆曲线的基点）
  服务端：生成随机数 b，计算 B = b × G

  客户端发 A 给服务端，服务端发 B 给客户端

  客户端计算：S = a × B = a × (b × G) = (ab) × G
  服务端计算：S = b × A = b × (a × G) = (ab) × G

  → 双方得到相同的点 S，取 S 的 x 坐标作为共享密钥
  → 窃听者只知道 G、A、B，但无法计算 a 或 b（椭圆曲线离散对数难题）
  → 每一步都使用临时私钥（Ephemeral），不长期保存，保证前向安全性
```

**椭圆曲线相比有限域 DH 的优势**：同安全强度下密钥更短（256 位 ECC ≈ 3072 位 RSA）、计算更快。

### 1-RTT 完整握手流程

```
Client                                            Server
  |                                                  |
  | --- ClientHello (Client Random, Key Share) ----> |
  |                  (1 个 RTT)                      |
  | <-- ServerHello (Server Random, Key Share) ----- |
  | <-- {EncryptedExtensions} ------------------- -- |  ← 加密传输
  | <-- {Certificate} ------------------------------ |  ← 同一 Flight
  | <-- {CertificateVerify} ------------------------ |
  | <-- {Finished} --------------------------------- |
  |                                                  |
  | --- {Finished} -------------------------------> |
  |                                                  |
  | <============= Application Data ===============> |
```

#### 第 1 步：Client → Server（ClientHello）

客户端发送消息给服务器，包含：

- **Client Random**：32 字节随机数（TLS 1.3 中全部为随机数，不再包含时间戳）
- **支持的密码套件**：仅列出 TLS 1.3 套件（如 TLS_AES_128_GCM_SHA256）
- **Key Share**：客户端的一次性 ECDHE 公钥（可直接包含多个曲线的候选公钥）
- **Supported Versions**：支持的 TLS 版本列表（TLS 1.3 必填）
- **PSK Key Exchange Modes**（可选）：若支持会话恢复，标识可接受的密钥交换模式
- **其他扩展**：SNI（域名指示）、ALPN（应用层协议协商）等

> **TLS 1.3 的关键区别**：客户端在第一条消息中就发送了 ECDHE 公钥（Key Share），使服务器可以在收到后立即计算共享密钥，无需额外往返，这是实现 1-RTT 的核心。

#### 第 2 步：Server → Client（ServerHello + 加密 Flight）

服务器收到 ClientHello 后：

1. 选定密码套件和曲线
2. 生成自己的 ECDHE 密钥对，用客户端的 Key Share 计算出**共享密钥**（Handshake Secret）
3. 回复以下消息（**同一 Flight 内连续发送**）：

| 消息 | 加密与否 | 说明 |
|------|---------|------|
| **ServerHello** | ❌ 明文 | 包含 Server Random + 选定套件 + 服务器 ECDHE 公钥（Key Share） |
| **EncryptedExtensions** | ✅ 加密 | 不需要保护或不需要证书即可发送的扩展（如 ALPN、SNI） |
| **CertificateRequest** | ✅ 加密 | 可选，仅当服务器要求客户端证书时发送 |
| **Certificate** | ✅ 加密 | 服务器的数字证书链（TLS 1.3 中**证书加密传输**，防止泄露域名） |
| **CertificateVerify** | ✅ 加密 | 用**服务器私钥对截至目前所有握手消息的哈希值签名**，证明服务器持有证书私钥 |
| **Finished** | ✅ 加密 | 对截至目前所有握手消息的 MAC，确认握手完整性 |

> **密钥计算时序**：ServerHello 发完后，服务器立刻用 ECDHE 的 Key Share 计算出 Handshake Secret，然后用这个密钥**加密 EncryptedExtensions 及之后的所有消息**。Certificate 是在加密后才发送的，所以中间人无法看到证书内容。

#### 第 3 步：Client → Server（验证 + Finished）

客户端收到服务器的回复后：

1. **计算共享密钥**：用客户端的 ECDHE 私钥 + 服务器的 ECDHE 公钥，计算出相同的 Handshake Secret；
2. **解密 ServerHello 之后的消息**：用 Handshake Secret 解密 EncryptedExtensions、Certificate 等；
3. **验证证书**：验证服务器证书链的合法性（CA 签名、有效期、域名等）；
4. **验证签名**：用证书中的公钥验证 CertificateVerify 中的数字签名，确保证书和握手参数未被篡改；
5. **验证 Finished**：验证服务器发送的 Finished 消息，确认握手完整性；
6. **发送 {Finished}**：客户端发送加密的 Finished 消息（用当前 Handshake Secret 加密），确认客户端侧握手已完成；
7. 计算**应用数据密钥**（Traffic Secret），握手完成。

#### 第 4 步：应用数据传输

- 客户端和服务器使用通过 HKDF 派生的**应用数据密钥**（Application Traffic Secret）
- 使用 AEAD 加密算法（AES-GCM / ChaCha20-Poly1305）对应用数据进行对称加密传输
- **客户端可以在发送 Finished 时就带上应用数据**（1-RTT 的含义：从 ClientHello 到能发送数据，只需要 1 次网络往返）

### 0-RTT 会话恢复（PSK）

TLS 1.3 支持基于 **PSK（Pre-Shared Key，预共享密钥）** 的会话恢复，实现 0-RTT（零往返时间恢复）：

```
第一次完成握手（1-RTT）后，服务器发送 Session Ticket：
  Server → Client: {NewSessionTicket, PSK}（加密）

后续恢复连接时，客户端可以直接发送应用数据：
  Client → Server: ClientHello + PSK Key Exchange Mode + 0-RTT 数据（加密）
  Server → Client: ServerHello + Finished + 响应数据
```

| 对比项 | 1-RTT 完整握手 | 0-RTT 会话恢复（PSK） |
|--------|---------------|---------------------|
| **RTT** | 1 次往返 | 0 次（客户端直接发数据） |
| **是否需要证书** | ✅ 需要 | ❌ 不需要 |
| **适用场景** | 首次连接 | 最近连接过的服务器复用 |
| **安全性** | 最高 | 存在重放攻击风险（需应用层处理） |

### TLS 1.2 与 TLS 1.3 握手对比

| 对比项 | TLS 1.2（DH/ECDHE） | TLS 1.3 |
|--------|-------------------|---------|
| RTT 数 | 2-RTT | 1-RTT（完整），0-RTT（恢复） |
| ClientHello 中是否包含 KeyShare | ❌ 否 | ✅ 是（实现 1-RTT 的关键） |
| 证书传输时间 | 第 2 步明文传输 | 第 2 步**加密**传输 |
| ServerHelloDone 消息 | ✅ 有 | ❌ 无（简化） |
| ChangeCipherSpec | ✅ 有 | ✅ 保留（兼容性） |
| 密钥推导 | PRF（伪随机函数） | HKDF（基于 HMAC 的密钥推导） |
| MAC 机制 | 独立的 HMAC | AEAD 内嵌认证 |
| 前向安全性 | 仅 DHE/ECDHE 支持 | **所有套件都支持** |

---

## 十一、HTTPS 中间人攻击（MITM）与抓包原理

### 什么是中间人攻击？

中间人攻击（Man-in-the-Middle, MITM）是指攻击者在客户端和服务端之间拦截并篡改通信：

```
正常通信：              中间人攻击：
客户端 ←→ 服务端       客户端 ←→ 攻击者 ←→ 服务端
                        （客户端以为在和服务端通信
                         服务端以为在和客户端通信）
```

HTTPS 通过**证书验证 + 加密**来防御中间人攻击。如果攻击者无法提供合法的服务器证书，客户端会报警告。

### HTTPS 如何防御中间人攻击？

| 防御手段 | 防护目标 | 绕过条件 |
|---------|---------|---------|
| **证书验证** | 防止身份伪造 | 需要用户信任攻击者的 CA 证书 |
| **CertificateVerify 签名** | 防止参数篡改 | 攻击者需要持有服务器私钥 |
| **加密通信** | 防止窃听 | 无法绕过 |

### Charles 抓包原理

Charles 是一个流行的 HTTPS 抓包工具，之所以能在 HTTPS 加密环境下工作，是因为它**充当了一个中间人（MITM 代理）**，但需要用户主动信任 Charles 的根证书。

#### 抓包流程

```
正常 HTTPS 通信：
  App/浏览器（信任系统根证书）←→ 服务器（持有真实证书）

Charles 抓包时：
  App/浏览器（信任系统根证书 + Charles 证书）←→ Charles（用自己的证书冒充）←→ 服务器（真实连接）
```

**详细步骤**：

```
          App/浏览器                         Charles                          目标服务器
              │                                │                                │
              │  ------ 1. 安装 Charles 根证书 --│                                │
              │     （手动信任，系统提示风险）      │                                │
              │                                │                                │
              │  --- 2. 请求 https://example.com │                                │
              │-------------------------------->│                                │
              │                                │  --- 3. 代理请求 example.com     │
              │                                │-------------------------------->│
              │                                │                                │
              │                                │  <-- 4. 服务器返回真实证书 -------│
              │                                │                                │
              │                                │  5. Charles 用服务器证书建立连接  │
              │  <-- 6. Charles 返回伪造证书 ---│     （用 Charles 根证书签发的）    │
              │      （用 Charles 根证书签名）    │                                │
              │                                │                                │
              │  7. 客户端验证证书：             │                                │
              │     ✅ 证书链到 Charles 根证书    │                                │
              │     ✅ 客户端信任 Charles 根证书  │                                │
              │     ← 验证通过！                 │                                │
              │                                │                                │
              │  --- 8. ClientHello + KeyShare->│  --- 9. 代理 ClientHello ------>│
              │                                │-------------------------------->│
              │  <-- 10. 用 Charles 密钥加密 ---│  <-- 11. 用服务器密钥加密 -------│
              │                                │                                │
              │  12. Charles 解密流量并记录      │                                │
              │     之后加密转发给任一方          │                                │
```

#### Charles 的三段式加密

```
  ┌──────────┐        ┌──────────┐        ┌──────────┐
  │ 客户端    │        │ Charles  │        │ 服务端    │
  │          │ 加密1   │          │  加密2  │          │
  │ 对称密钥1│◄──────►│  明文    │◄──────►│ 对称密钥2│
  │          │        │  抓包记录│         │          │
  └──────────┘        └──────────┘        └──────────┘
```

- **加密1**：客户端与 Charles 之间的 TLS 连接，使用 Charles 自己签发的证书
- **加密2**：Charles 与服务器之间的 TLS 连接，使用服务器的真实证书
- **中间**：Charles 拥有两个链接的明文数据，可以记录和分析

#### Charles 抓包的局限性

| 情况 | 能否抓包 | 原因 |
|------|---------|------|
| App 信任系统根证书 + 已安装 Charles 证书 | ✅ 能 | Charles 用自己的证书冒充服务器 |
| App 仅信任系统根证书（未安装 Charles 证书） | ❌ 不能 | 证书验证失败：Charles 证书未受信任 |
| App 使用 SSL Pinning（证书绑定） | ❌ 不能 | App 固定了服务器证书，Charles 证书不匹配 |
| App 使用 SSL Pinning + 已安装 Charles 证书 | ❌ 不能 | SSL Pinning 在代码中硬编码证书，不依赖系统信任 |

#### SSL Pinning（证书绑定）

SSL Pinning 是一种防止中间人抓包的机制，App **在代码中固定服务器的证书或公钥**，不依赖系统信任链：

```swift
// SSL Pinning 示例：固定服务器公钥
class PinnedDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            return completionHandler(.cancelAuthenticationChallenge, nil)
        }

        // 获取服务器证书
        let serverCert = SecTrustCopyCertificateChain(serverTrust)!.first!
        let serverCertData = SecCertificateCopyData(serverCert as! SecCertificate) as NSData

        // 对比本地硬编码的证书
        let localCertData = // 从 Bundle 中加载预先保存的证书

        if serverCertData.isEqual(to: localCertData as Data) {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}
```

### 面试常见问题

#### 1. HTTPS 既然加密了，为什么 Charles 能抓到包？

因为 Charles 用了**中间人攻击**的方式——用户在手机上主动安装了 Charles 的根证书，所以 Charles 可以用自己的证书冒充任意服务器。如果没有安装 Charles 的证书，或者 App 做了 SSL Pinning，Charles 就抓不到包。

#### 2. 如何防止 App 被 Charles 抓包？

1. **SSL Pinning**：在代码中固定服务器证书或公钥
2. **双向认证（Mutual TLS）**：服务器也验证客户端证书
3. **禁止用户安装的根证书**：仅信任系统内置的根证书（iOS 14+ 可通过 `SecTrustStore` 配置）
4. **证书透明度（Certificate Transparency）**：检查证书是否有公开日志记录

#### 3. Charles 抓包时，App 会报警告吗？

如果 App 没有做 SSL Pinning，且用户已安装 Charles 证书，HTTPS 连接会**静默成功**（Charles 返回的证书在客户端验证通过），App 不会产生任何警告。用户完全感知不到正在被抓包。

#### 4. 公司和学校能监控员工的 HTTPS 流量吗？

可以，原理和 Charles 完全一样——公司在员工的设备上安装公司的根证书，然后通过代理服务器解密所有 HTTPS 流量。这是合法的（设备属于公司），但通常会在合规协议中告知员工。

---

## 十二、数字证书验证

### 证书链（Chain of Trust）

数字证书采用**信任链**机制：

```
根证书（Root CA）  ←  操作系统 / 浏览器内置，自签名，是信任的根
    │
    └── 中间证书（Intermediate CA）
            │
            └── 终端证书（End-entity Certificate）  ←  服务器使用的证书
```

### 验证流程

1. **找到信任的根证书**：从系统或浏览器的受信任根证书库中找到颁发该证书的 CA 根证书；
2. **验证签名**：用上级证书中的公钥验证下级证书的数字签名，逐级验证直到根证书；
3. **验证指纹**：
   - 用上级证书的公钥解密下级证书的数字签名，得到证书的**指纹 h1**和指纹算法（指纹是证书内容通过哈希算法计算得到的摘要）；
   - 用相同的指纹算法对当前接收到的证书内容重新计算哈希，得到 **h2**；
   - 比较 h1 和 h2：如果相等，说明证书内容未被篡改；如果不等，说明证书已被篡改。
4. **其他校验**：
   - 检查证书是否在**有效期**内；
   - 检查证书的**域名**是否与访问的域名匹配；
   - 检查证书是否被**吊销**（通过 CRL 或 OCSP）。

> 由于哈希算法具有唯一性（不同内容不可能产生相同的哈希值），如果证书被篡改过，h1 和 h2 必然不同。

---

## 十三、HTTP 请求方法

| 方法 | 说明 | 幂等 | 安全 |
| --- | --- | --- | --- |
| GET | 获取资源 | ✅ | ✅ |
| POST | 提交数据 / 创建资源 | ❌ | ❌ |
| PUT | 更新 / 替换资源（完整替换） | ✅ | ❌ |
| DELETE | 删除资源 | ✅ | ❌ |
| PATCH | 部分更新资源 | ❌ | ❌ |
| HEAD | 获取报文首部（不含实体主体） | ✅ | ✅ |
| OPTIONS | 查询支持的方法 | ✅ | ✅ |
| CONNECT | 建立隧道连接（用于代理） | ❌ | ❌ |
| TRACE | 回显服务器收到的请求（用于诊断） | ✅ | ✅ |

> **幂等**：多次执行相同请求，产生的效果与一次执行相同。
> **安全**：不会改变服务器上的资源状态。

---

## 十四、HTTP 报文首部字段

### 1. 通用首部字段（General Header）

| 首部字段 | 说明 |
| --- | --- |
| Cache-Control | 控制缓存行为 |
| Connection | 管理持久连接（keep-alive / close） |
| Date | 报文创建的日期时间 |
| Transfer-Encoding | 报文主体的传输编码（如 chunked） |
| Upgrade | 升级为其他协议 |
| Via | 代理服务器的相关信息 |
| Warning | 警告信息 |

### 2. 请求首部字段（Request Header）

| 首部字段 | 说明 |
| --- | --- |
| Accept | 客户端可处理的媒体类型 |
| Accept-Charset | 客户端优先的字符集 |
| Accept-Encoding | 客户端支持的内容编码 |
| Accept-Language | 客户端优先的自然语言 |
| Authorization | Web 认证信息 |
| Cookie | 客户端发送的 Cookie |
| Host | 请求资源所在的主机名和端口号 |
| If-Modified-Since | 比较资源的更新时间（缓存验证） |
| If-None-Match | 比较资源的 ETag（缓存验证） |
| Referer | 请求发起的原始 URI |
| User-Agent | 客户端程序信息 |

### 3. 响应首部字段（Response Header）

| 首部字段 | 说明 |
| --- | --- |
| Accept-Ranges | 是否接受字节范围请求 |
| Age | 资源经过代理缓存的时间 |
| ETag | 资源的唯一标识 |
| Location | 重定向的目标 URI |
| Server | 服务器软件信息 |
| Set-Cookie | 设置 Cookie |
| WWW-Authenticate | 服务器要求的认证信息 |

### 4. 实体首部字段（Entity Header）

| 首部字段 | 说明 |
| --- | --- |
| Allow | 资源支持的 HTTP 方法 |
| Content-Encoding | 实体主体的编码方式 |
| Content-Language | 实体主体的自然语言 |
| Content-Length | 实体主体的大小（字节） |
| Content-Type | 实体主体的媒体类型 |
| Expires | 资源的过期时间 |
| Last-Modified | 资源的最后修改时间 |

> 原始图片参考（简书）：[通用首部](https://upload-images.jianshu.io/upload_images/1846524-3558a33201ed858e.png)、[请求首部](https://upload-images.jianshu.io/upload_images/1846524-43fb1269ba681b49.png)、[响应首部](https://upload-images.jianshu.io/upload_images/1846524-f412b63266a0af22.png)、[实体首部](https://upload-images.jianshu.io/upload_images/1846524-a18a912e0a2e6213.png)

---

## 十五、GET 与 POST 的区别

| 对比项 | GET | POST |
| --- | --- | --- |
| 参数位置 | URL 后面（Query String） | 请求主体（Body）中 |
| 安全性 | 参数暴露在 URL 中，不安全 | 参数在请求体中，相对安全 |
| 浏览器记录 | 参数会被完整保留在浏览器记录中 | 参数不会被保留 |
| 编码格式 | 仅支持 URL 编码 | 支持多种编码格式 |
| 字符限制 | 仅支持 ASCII 字符 | 无限制 |
| 数据大小 | 受浏览器 URL 长度限制（通常 2KB~8KB） | 理论上无限制（受服务器配置限制） |
| 幂等性 | 幂等 | 非幂等 |
| 缓存 | 可被缓存 | 默认不缓存 |
| TCP 数据包 | 通常 1 个 | 部分浏览器会分 2 个（先发 Header，再发 Body） |

> **注意**：关于"GET 产生 1 个 TCP 数据包，POST 产生 2 个"并非 HTTP 规范要求，而是部分浏览器（如 Firefox/Chrome）的实现行为，POST 先发送 Header 再发送 Body，并非所有浏览器都如此。

---

## 十六、HTTP 与 HTTPS 的区别

| 对比项 | HTTP | HTTPS |
| --- | --- | --- |
| 证书 | 不需要 | 需要向 CA 申请证书（免费证书较少，通常需要费用） |
| 传输方式 | 明文传输 | SSL/TLS 加密传输 |
| 端口 | 80 | 443 |
| 安全性 | 无加密、无身份认证 | 加密传输 + 身份认证 |
| 状态 | 无状态 | 由 SSL + HTTP 构建的安全协议 |
| 性能 | 较快 | 握手增加延迟，加密消耗 CPU |

---

## 十七、浏览器中输入 URL 后发生了什么

参考：[从输入 URL 到页面展示发生了什么](https://www.jianshu.com/p/c1dfc6caa520)

简要流程：

1. **URL 解析**：浏览器解析输入的内容，判断是搜索关键词还是 URL，补全协议名；
2. **DNS 解析**：将域名解析为 IP 地址（先查本地缓存 → 系统缓存 → 路由器缓存 → ISP DNS → 递归查询）；
3. **建立 TCP 连接**：三次握手建立 TCP 连接；
4. **TLS 握手**（如果是 HTTPS）：进行 TLS 握手，协商加密参数，生成 Session Key；
5. **发送 HTTP 请求**：浏览器构造 HTTP 请求报文并发送给服务器；
6. **服务器处理请求**：服务器接收请求，处理后返回 HTTP 响应；
7. **浏览器渲染**：
   - 解析 HTML 构建 DOM 树；
   - 解析 CSS 构建 CSSOM 树；
   - 合并为渲染树（Render Tree）；
   - 布局（Layout / Reflow）；
   - 绘制（Paint）；
   - 合成（Composite）；
8. **断开连接**：根据 Connection 头决定是否保持连接或四次挥手断开。

---

## 十八、Cookie、Session 与 Token

HTTP 是无状态协议，服务器默认不会记住客户端的身份。为了实现"有状态"的通信（如用户登录），需要借助 Cookie、Session 或 Token 机制。

### 1. Cookie

Cookie 是服务器发送到浏览器并保存在本地的一小块数据（通常 ≤ 4KB），浏览器后续请求同一域名时会自动携带。

#### 工作流程

```
1. 客户端发送登录请求（用户名 + 密码）
2. 服务器验证通过后，在响应头中设置 Set-Cookie
3. 浏览器保存 Cookie
4. 后续请求自动在请求头中携带 Cookie
```

#### Cookie 的属性

| 属性 | 说明 |
| --- | --- |
| `Name=Value` | Cookie 的键值对 |
| `Expires` / `Max-Age` | 过期时间，不设置则为会话级 Cookie（关闭浏览器即失效） |
| `Domain` | Cookie 生效的域名 |
| `Path` | Cookie 生效的路径 |
| `Secure` | 仅在 HTTPS 下发送 |
| `HttpOnly` | 禁止 JavaScript 访问（防止 XSS 窃取） |
| `SameSite` | 跨站发送策略（`Strict` / `Lax` / `None`，防止 CSRF） |

#### 示例

```
// 服务器响应
Set-Cookie: sessionId=abc123; Path=/; HttpOnly; Secure; SameSite=Lax; Max-Age=3600

// 客户端后续请求
Cookie: sessionId=abc123
```

#### 缺点

- 保存在客户端，存在被篡改的风险；
- 容量有限（通常 4KB），不适合存储大量数据；
- 在跨域请求中携带 Cookie 需要额外配置（CORS）。

---

### 2. Session

Session 是服务器端的会话管理机制。服务器为每个客户端创建一个 Session 对象，通过 Session ID 来标识，Session ID 通常通过 Cookie 传递。

#### 工作流程

```
1. 客户端首次请求（无 Cookie）
2. 服务器创建 Session，生成唯一的 Session ID
3. 服务器通过 Set-Cookie 将 Session ID 返回给客户端
4. 客户端后续请求携带 Session ID（通过 Cookie）
5. 服务器根据 Session ID 查找对应的 Session，获取用户状态
```

```
Client                                    Server
  |                                          |
  | --- POST /login (user, pwd) -----------> |
  |                                          | ← 创建 Session，生成 SessionID
  | <-- 200 OK (Set-Cookie: JSESSIONID=xxx)  |
  |                                          |
  | --- GET /profile (Cookie: JSESSIONID=x)->|
  |                                          | ← 根据 SessionID 查找 Session
  | <-- 200 OK (用户信息) ------------------- |
```

#### Session 的存储方式

| 存储方式 | 说明 |
| --- | --- |
| 内存 | 速度最快，但服务器重启后丢失，不利于分布式 |
| 文件 | 持久化到磁盘，性能略低 |
| 数据库 | 如 Redis / MySQL，适合分布式部署 |
| Cookie | 将 Session 数据加密后存入 Cookie（不推荐存敏感数据） |

#### Session vs Cookie

| 对比项 | Cookie | Session |
| --- | --- | --- |
| 存储位置 | 客户端（浏览器） | 服务器端 |
| 安全性 | 较低（可被篡改） | 较高（客户端只持有 Session ID） |
| 容量 | 约 4KB | 受服务器内存限制 |
| 生命周期 | 由 Expires / Max-Age 控制 | 由服务器超时配置控制 |
| 分布式支持 | 天然支持 | 需要 Session 共享（如 Redis） |

#### 缺点

- 服务器需要存储 Session 数据，占用内存 / 磁盘资源；
- 分布式环境下需要解决 Session 共享问题（Sticky Session、Session 复制、集中存储等）；
- 基于 Cookie 传递 Session ID，存在 CSRF 风险。

---

### 3. Token（JWT）

Token 是一种无状态的认证机制。服务器不存储 Token 状态，而是通过签名验证 Token 的合法性。最常用的 Token 格式是 **JWT（JSON Web Token）**。

#### JWT 结构

JWT 由三部分组成，以 `.` 分隔：`Header.Payload.Signature`

```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4iLCJpYXQiOjE1MTYyMzkwMjJ9.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c
```

| 部分 | 说明 | 示例 |
| --- | --- | --- |
| **Header** | 头部，声明 Token 类型和签名算法 | `{"alg": "HS256", "typ": "JWT"}` |
| **Payload** | 载荷，存放声明（Claims），如用户 ID、过期时间等 | `{"sub": "123", "name": "John", "iat": 1516239022}` |
| **Signature** | 签名，用私钥 / 密钥对 Header + Payload 签名，防止篡改 | `HMACSHA256(base64(Header) + "." + base64(Payload), secret)` |

> **注意**：Payload 默认只是 Base64 编码，**不是加密**，不要存放敏感信息。

#### 工作流程

```
1. 客户端发送登录请求（用户名 + 密码）
2. 服务器验证通过后，生成 JWT 并返回
3. 客户端保存 Token（通常存在 localStorage 或 Cookie 中）
4. 后续请求在 Authorization 头中携带 Token
5. 服务器验证 Token 的签名和有效期，提取用户信息
```

```
Client                                    Server
  |                                          |
  | --- POST /login (user, pwd) -----------> |
  |                                          | ← 验证通过，生成 JWT
  | <-- 200 OK (Token: eyJhbG...)           |
  |                                          |
  | --- GET /profile (Authorization: Bearer) |
  |                                  Token-->| ← 验证签名 + 过期时间
  | <-- 200 OK (用户信息) ------------------- |
```

#### 请求携带方式

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

#### Token 的分类

| 类型 | 说明 |
| --- | --- |
| **Access Token** | 访问令牌，有效期短（如 15 分钟 ~ 2 小时），用于 API 认证 |
| **Refresh Token** | 刷新令牌，有效期长（如 7 天 ~ 30 天），用于获取新的 Access Token，通常存储在 HttpOnly Cookie 中 |

#### 优点

- **无状态**：服务器不需要存储 Session，天然支持分布式；
- **跨域友好**：通过 Header 携带，不受 Cookie 跨域限制；
- **移动端友好**：原生 App、小程序等场景下比 Cookie 更方便。

#### 缺点

- Token 一旦签发，在过期前无法主动撤销（除非维护黑名单）；
- Token 体积比 Session ID 大，每次请求都要携带；
- Payload 未加密，不能存放敏感数据。

---

### 4. 三者对比

| 对比项 | Cookie | Session | Token（JWT） |
| --- | --- | --- | --- |
| 存储位置 | 客户端 | 服务器端 | 客户端 |
| 服务器状态 | 无状态 | 有状态 | 无状态 |
| 安全性 | 较低 | 较高 | 较高（签名防篡改） |
| 分布式支持 | 天然支持 | 需要共享 | 天然支持 |
| 跨域支持 | 需要额外配置（CORS） | 需要额外配置 | 天然支持 |
| 过期/撤销 | 可设置过期时间 | 服务器控制 | 过期前无法撤销（需黑名单） |
| 移动端 | 不友好 | 不友好 | 友好 |
| 适用场景 | 简单状态保持 | 传统 Web 应用 | 前后端分离 / 移动端 / 微服务 |

---

### 5. 面试常见问题

#### Cookie 如何防范 XSS？

- 设置 `HttpOnly` 属性，禁止 JavaScript 读取 Cookie；
- 对用户输入进行转义 / 过滤，防止恶意脚本注入。

#### Cookie 如何防范 CSRF？

- 设置 `SameSite` 属性（`Strict` 或 `Lax`）；
- 服务器校验 `Referer` 或 `Origin` 头；
- 使用 CSRF Token（与 JWT 无关，是在表单中嵌入一个随机值）。

#### JWT 被盗怎么办？

- 缩短 Access Token 的有效期；
- 使用 HTTPS 防止中间人攻击；
- 维护 Token 黑名单（牺牲无状态特性）；
- Refresh Token 存储在 HttpOnly Cookie 中，降低被盗风险。

#### 分布式 Session 如何解决？

1. **Sticky Session**（Nginx ip_hash）：同一 IP 的请求固定路由到同一服务器；
2. **Session 复制**：服务器之间同步 Session（适合小集群）；
3. **集中存储**：将 Session 统一存储到 Redis / Memcached（最常用）。
