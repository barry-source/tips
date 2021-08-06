
# HTTPS工作流程

## HTTPS工作流程
![3od2nnpd7w.jpeg](https://upload-images.jianshu.io/upload_images/1846524-ed93272f69664097.jpeg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)



过程大致如下：

### 一、tcp连接和获取证书：`（涉及证书加密）`

SSL客户端通过TCP和服务器建立连接之后（443端口），并且在一般的tcp连接协商（握手）过程中请求证书。

即客户端发出一个消息给服务器，这个消息里面包含了自己可实现的算法列表和其它一些需要的消息，SSL的服务器端会回应一个数据包，这数据包里面确定了这次通信所需要的算法，然后服务器将自己的身份信息以证书的形式发回客户端。证书里面包含了服务器信息：域名或者服务地址、加密公钥、以及证书的颁发机构。   

### 二、Client在收到服务器返回的证书后处理：`（涉及非对称加密）`

1）验证证书的合法性：颁发证书的机构是否合法、并使用这个机构的公共秘钥确认签名是否有效，确保证书中列出的域名就是它正在连接的域名。如果是浏览器客户端，若证书受信任，则浏览器栏里面会显示一个小锁头，否则会给出证书不受信的提示。

2）  如果确认证书有效，那么生成对称秘钥并使用服务器的公共秘钥进行加密（发送一段信息用对称密钥加密，并用公钥再次加密）。然后发送给服务器。

### 三、服务端接收客户端发来的数据之后要做以下的操作：`（涉及对称加密）`

使用自己的私钥将信息解密取出密码，使用对称密钥解密客户端发来的握手消息，并验证HASH是否与浏览器发来的一致。

使用对称密钥加密一段握手消息，发送给客户端。客户端解密并计算握手消息的HASH，如果与服务端发来的HASH一致，此时握手过程结束。

### 四、之后所有的通信数据将由之前浏览器生成的随机密码并利用加密算法进行加密。


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

