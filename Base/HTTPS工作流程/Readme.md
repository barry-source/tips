
# HTTPS工作流程

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

客户端发出一个消息给服务器，这个消息里面包含了客户端需要使用的协议版本，随机数（`Client random`，自己可实现的算法列表和其它一些握手消息

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

客户端发出一个消息给服务器，这个消息里面包含了客户端需要使用的协议版本，随机数（`Client random`，自己可实现的算法列表和其它一些握手消息

### 2 服务器向客户端发消息

服务器在接收到客户端的消息后，会回应客户端一个消息，这个消息里面包含一个随机数（`Server random`）,选取的加密算法套件（包括ECDHE）和服务器的证书，证书内部包含公钥，域名以及证书的颁发机构

### 3 服务器向客户端发送参数
服务器向客户端发送参与生成`pre-main secret`的key，并且对发送的信息进行校验生成hash一并发送给客户端

### 4 

验证证书的合法性，如果合法的话，并校验发送来的信息。如果无异常的，话，客户端将发送自己参与生成`pre-main secret`的key，这是两端都知道了`pre-main secret`，再加上两个随机数也就知道了`session key`，然后利用`session key`发送一段信息来验证信息是否被加密，握手过程结束

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


