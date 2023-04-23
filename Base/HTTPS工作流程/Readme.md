
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
