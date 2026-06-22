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

## 六、HTTPS 名词解释

| 名称 | 说明 |
| --- | --- |
| **Session Key** | 握手结束时生成的对称加密密钥，用于加密服务器和客户端之间的通信数据 |
| **Client Random** | 客户端生成的 32 字节随机数（TLS 1.2 中前 4 字节为时间戳，后 28 字节为随机数；TLS 1.3 中全部为随机数） |
| **Server Random** | 服务器生成的 32 字节随机数，格式同上 |
| **Pre-master Secret** | 48 字节的预主密钥，与 Client Random、Server Random 一起通过伪随机函数（PRF）生成 Session Key |
| **Cipher Suite** | 加密套件，唯一标识 TLS 连接所使用的一组算法，包含以下四个部分：<br>• **密钥交换**（Key Exchange）：RSA / DHE / ECDHE<br>• **身份认证**（Authentication）：RSA / ECDSA<br>• **对称加密**（加密 / 解密）：AES / ChaCha20<br>• **消息认证**（完整性校验）：SHA-256 / SHA-384 / AEAD |

---

## 七、RSA 握手流程（TLS 1.2）

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

## 八、DH 握手流程（TLS 1.2）

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

## 九、TLS 1.3 握手流程

TLS 1.3 对握手流程进行了大幅简化，从 2-RTT 减少到 **1-RTT**，并支持 **0-RTT**（早期数据）。

### 主要改进

- 移除了 RSA 密钥交换等不具备前向安全性的算法，**仅保留 ECDHE**；
- 握手消息加密：ServerHello 之后的握手消息都是加密的；
- 支持会话恢复（Session Resumption），可实现 0-RTT；
- 移除了独立的 MAC，统一使用 **AEAD**（如 AES-GCM、ChaCha20-Poly1305）。

### 1-RTT 握手流程

```
Client                                            Server
  |                                                  |
  | --- ClientHello (Client Random, Key Share) ----> |
  |                                                  |
  | <-- ServerHello (Server Random, Key Share) ----- |
  | <-- {EncryptedExtensions} --------------------- |
  | <-- {Certificate} ----------------------------- |
  | <-- {CertificateVerify} ----------------------- |
  | <-- {Finished} -------------------------------- |
  |                                                  |
  | --- {Finished} ------------------------------> |
  |                                                  |
  | <============= Application Data ===============> |
```

1. **ClientHello**：客户端发送 Client Random、支持的密码套件、以及 ECDHE 公钥（Key Share）；
2. **ServerHello**：服务器回应 Server Random、选定的密码套件、以及 ECDHE 公钥（Key Share）；
3. 此时双方已可计算出共享密钥，后续握手消息（EncryptedExtensions、Certificate、CertificateVerify、Finished）都是**加密**的；
4. 客户端验证证书和签名后，发送 Finished，握手结束，开始传输应用数据。

> TLS 1.3 的所有密钥交换算法都具备前向安全性。

---

## 十、数字证书验证

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

## 十一、HTTP 请求方法

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

## 十二、HTTP 报文首部字段

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

## 十三、GET 与 POST 的区别

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

## 十四、HTTP 与 HTTPS 的区别

| 对比项 | HTTP | HTTPS |
| --- | --- | --- |
| 证书 | 不需要 | 需要向 CA 申请证书（免费证书较少，通常需要费用） |
| 传输方式 | 明文传输 | SSL/TLS 加密传输 |
| 端口 | 80 | 443 |
| 安全性 | 无加密、无身份认证 | 加密传输 + 身份认证 |
| 状态 | 无状态 | 由 SSL + HTTP 构建的安全协议 |
| 性能 | 较快 | 握手增加延迟，加密消耗 CPU |

---

## 十五、浏览器中输入 URL 后发生了什么

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

# HTTPS工作流程

## http相关概念

URI = URL + URN 大致看成是URL和URN的集合，但是URL和URN之间有交集
URI：Uniform Resource Identifier
URL：Uniform Resource Locator
URN：Uniform Resource Name

URI: (scheme://)(host:port)(/path)(?query) 由 scheme 、authority（host：port）、path和query四部分组成

scheme 叫“方案名”或者“协议名”，表示资源应该使用哪种协议来访问（http,https,ftp等）
authority 表示资源所在的主机名和端口号；
path 标记资源所在的位置
query 表示对资源附加的额外要求
在 URI 里对“@&/”等特殊字符和汉字必须要做编码，否则服务器收到 HTTP 报文后会无法正确处理。

//////////////////////////////////////////////////////////
## http 常用状态码
状态码在响应报文里表示了服务器对请求的处理结果；
状态码后的原因短语是简单的文字描述，可以自定义；
状态码是十进制的三位数，分为五类，从 100 到 599；
2××类状态码表示成功，常用的有 200(ok)、204( No Content)、206(Partial Content，断点续传)；
3××类状态码表示重定向，常用的有 301(永久重定向)、302(临时重定向)、304(Not Modified 缓存重定向)；
4××类状态码表示客户端错误，常用的有 400(Bad Request)、403(Forbidden)、404(Not Found)；
5××类状态码表示服务器错误，常用的有 500( Internal Server Error)、501(Not Implemented)、502(Bad Gateway)、503(Service Unavailable)。

//////////////////////////////////////////////////////////
## http特点

* HTTP 是灵活可扩展的，可以任意添加头字段实现任意功能；
* HTTP 是可靠传输协议，基于 TCP/IP 协议“尽量”保证数据的送达；
* HTTP 是应用层协议，比 FTP、SSH 等更通用功能更多，能够传输任意数据；
* HTTP 使用了请求 - 应答模式，客户端主动发起请求，服务器被动回复请求；
* HTTP 本质上是无状态的，每个请求都是互相独立、毫无关联的，协议不要求客户端或服务器记录请求相关的信息

//////////////////////////////////////////////////////////
## http优缺点 HTTP/1.1

优点：
HTTP 最大的优点是简单、灵活和易于扩展；
HTTP 拥有成熟的软硬件环境，应用的非常广泛，是互联网的基础设施；
HTTP 是无状态的，可以轻松实现集群化，扩展性能，但有时也需要用 Cookie 技术来实现“有状态”；
缺点：
HTTP 是明文传输，数据完全肉眼可见，能够方便地研究分析，但也容易被窃听；
HTTP 是不安全的，无法验证通信双方的身份，也不能判断报文是否被窜改；
HTTP 的性能不算差，但不完全适应现在的互联网，还有很大的提升空间。

[HTTPS工作流程](https://blog.cloudflare.com/keyless-ssl-the-nitty-gritty-technical-details/)

## 名词解释：

- `Session key`: 握手结束时，会产生一个对称加密的`key`，利用这个key 来加密服务商和客户端的通信 
- `Client random`: 由客户端产生的一个32Byte的序列
- `Server random`: 同上
- `Pre-main secret`: 占用48个字节的序列，它和`Client random` ,`Server random`利用伪随机函数(PRF)生成 `Session key`
- `Cipher suite`: 加密套件，这是用于组合组成TLS连接的算法的唯一标识符，它定义下列算法之一：
    
    - key establishment：确认key（RSA）
    - authentication： 证书类型
    - confidentiality： 保密性（对称加密 ）
    - integrity： 完整性（hash校验）
    
## 1、 RSA

![rsa.png](https://upload-images.jianshu.io/upload_images/1846524-6c9abb7f17c308fa.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

流程如下：

### 1 客户端向服务器发消息

客户端发出一个消息给服务器，这个消息里面包含了随机数（`Client random`），自己可实现的算法列表，客户端需要使用的SSL协议版本和其它一些握手消息

### 2 服务器向客户端发消息 `（涉及证书加密, RSA）`

服务器在接收到客户端的消息后，会回应客户端一个消息，这个消息里面包含一个随机数（`Server random`）,选取的加密算法套件和服务器的证书，证书内部包含公钥，域名以及证书的颁发机构

### 3  `（涉及对称加密）`

验证证书的合法性，如果合法的话，客户端产生一个叫`pre-main secret`的随机数，并用公钥加密发送给服务器，服务器利用私钥解决取出`pre-main secret`，这时服务器和客户端都有了同样的`session key`, 然后利用`session key`发送一段信息来验证信息是否被加密，握手过程结束。后续服务器和客户端的消息都会利用`session key`进行加密


总结：

RSA握手的缺点是只要私钥泄漏了，并且记录了握手过程和后续的通信过程，那么`pre-main secret`就会被解密，进而获取`session key`

## 2、DH握手
它采用两个 不同的机制：一个是创建共享的`pre-main secret`,另一个是服务器的认证，主要依赖DH算法。
DH算法的原理是指数是可交换的，两端交换信息之后就可以都可以获取到共享的`pre-main secret`

![DH.png](https://upload-images.jianshu.io/upload_images/1846524-cbc80f6490f9aff0.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


### 1 客户端向服务器发消息

客户端发出一个消息给服务器，这个消息里面包含了客户端需要使用的SSL协议版本，随机数（`Client random`，自己可实现的算法列表和其它一些握手消息

### 2 服务器向客户端发消息

服务器在接收到客户端的消息后，会回应客户端一个消息，这个消息里面包含一个随机数（`Server random`）,选取的加密算法套件（包括ECDHE）和服务器的证书，证书内部包含公钥，域名以及证书的颁发机构

### 3 服务器向客户端发送参数
服务器向客户端发送参与生成`pre-main secret`的key，并且对发送的信息进行校验生成hash一并发送给客户端

### 4 

验证证书的合法性，如果合法的话，并校验发送来的信息。如果无异常的，话，客户端将发送自己参与生成`pre-main secret`的key，这是两端都知道了`pre-main secret` (这里的secret是利用DH算法得出来的)，再加上两个随机数也就知道了`session key`，然后利用`session key`发送一段信息来验证信息是否被加密，握手过程结束


在以上的流程中，应用层发送数据时会附加一个MAC的的报文摘要，MAC能够查知报文是否遭到篡改。

总结：DH握手算法有RSA 和DH算法，而RSA握手只包含RSA算法，另外DH算法计算特别慢，





> 面试： HTTP消息的header都有哪些


1、通用首部字段：

![通用首部.png](https://upload-images.jianshu.io/upload_images/1846524-3558a33201ed858e.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

2、请求首部字段

![请求首部.png](https://upload-images.jianshu.io/upload_images/1846524-43fb1269ba681b49.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

3、响应首部字段

![响应首部.png](https://upload-images.jianshu.io/upload_images/1846524-f412b63266a0af22.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

![image.png](https://upload-images.jianshu.io/upload_images/1846524-5eff99fcc5527957.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
4、实体首部字段

![实体首部.png](https://upload-images.jianshu.io/upload_images/1846524-a18a912e0a2e6213.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


### 浏览器中输入url后发生了什么

[参考](https://www.jianshu.com/p/c1dfc6caa520)


> 面试题：数字证书怎么验证真假


如果我们找到了证书颁发机构的根证书，那么就从根证书中取得那个根公钥，用根公钥去解密此证书的数字签名，成功解密的话就得到证书的指纹和指纹算法，指纹是证书内容通过指纹算法计算得到的一个hash值，这里我们称之为h1，h1代表证书的原始内容；然后用指纹算法对当前接收到的证书内容再进行一次hash计算得到另一个值h2，h2则代表当前证书的内容，如果此时h1和h2是相等的，就代表证书没有被修改过。如果证书被篡改过，h2和h1是不可能相同的，因为hash值具有唯一性，不同内容通过hash计算得到的值是不可能相同的

### get post 区别

- get 提交的数据会放在 URL 之后，并且请求参数会被完整的保留在浏览器的记录里，由于参数直接暴露在 URL 中，可能会存在安全问题，因此往往用于获取资源信息。而 post 参数放在请求主体中，并且参数不会被保留，相比 get 方法，post 方法更安全，主要用于修改服务器上的资源。
- get 请求只支持 URL 编码，post 请求支持多种编码格式。
- get 只支持 ASCII 字符格式的参数，而 post 方法没有限制。
- get 提交的数据大小有限制（这里所说的限制是针对浏览器而言的），而 post 方法提交的数据没限制
- get 方式需要使用 Request.QueryString 来取得变量的值，而 post 方式通过 Request.Form 来获取。
- get 方法产生一个 TCP 数据包，post 方法产生两个（并不是所有的浏览器中都产生两个）。


HTTPS和HTTP的区别主要如下：

- 1、https协议需要到ca申请证书，一般免费证书较少，因而需要一定费用。

- 2、http是超文本传输协议，信息是明文传输，https则是具有安全性的ssl加密传输协议。

- 3、http和https使用的是完全不同的连接方式，用的端口也不一样，前者是80，后者是443。

- 4、http的连接很简单，是无状态的；HTTPS协议是由SSL+HTTP协议构建的可进行加密传输、身份认证的网络协议，比http协议安全。
