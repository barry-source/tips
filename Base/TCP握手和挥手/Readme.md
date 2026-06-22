
# TCP和UDP

## 三次握手
![三次握手](https://upload-images.jianshu.io/upload_images/1846524-4d755479d5966fd8.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


### 解释
```
第一次握手：建立连接时，客户端发送syn包(包含随机的序列号`seq=1000`)到服务器，并进入SYN_SEND状态，等待服务器确认； 

第二次握手：服务器收到syn包，必须确认客户的`SYN（ack=1000 + 1`），同时自己也发送一个SYN包（包含随机的序列号`seq=2000`），即`SYN + ACK`包，此时服务器进入`SYN_RECV`状态；

第三次握手：客户端收到服务器的`SYN ＋ ACK`包，向服务器发送确认包`ACK(ack=2000+1)`，此包发送完毕，客户端和服务器进入`ESTABLISHED`状态，完成三次握手。 完成三次握手，客户端与服务器开始传送数据.
```

- 上述1000 和 2000 是随机的，这里为了演示写死了

### 三次握手的目的

- 确认双方收发能力正常（Client 能收发、Server 能收发）
- 双方初始化序列号 seq （TCP 初始化序列号是为了防止旧连接数据混入新连接、避免重放攻击、保证数据按序传输，以及确保连接的唯一性和安全性）
- 避免历史连接（老旧 SYN）建立错误连接

### 通俗解释

三次握手的比喻：
两个素未谋面的人遇见了，其中一个人(client端)想认识对方(server端)喔..于是那个人主动向对方挥手（意味着接下来有握手的冲动，即是带SYN标志的TCP报文到服务器），
而对方也向那个人挥手去握对方的手（对刚才客户端SYN报文的回应；同时又标志SYN给客户端，询问客户端是否准备好进行数据通讯），
这时候对方是否愿意握那个人的手（来自防火墙定义的规则决定），那个人确认了对方愿意才能走过去握手（客户必须再次回应服务段一个ACK报文），这样就达到了三次握手（建立连接）的原理；

### 再简单点就是，client 发送同步信号，sever接收到并对同步信号进行回应，回应的同时发送自己的同步信号，client接收到sever的响应的同时也接收到sever的同步信号，同样也要对同步信号进行回应，回应之后client和sever就建立了连接

## 四次挥手

![20200922015436601.png](https://upload-images.jianshu.io/upload_images/1846524-9c1ee9d2555d2aa0.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


### 解释

```第一次挥手：client向server发送FIN报文段(finish)，表示关闭数据传送并且client进入FIN_WAIT_1状态，表示没有数据要传输了
第二次挥手:server收到FIN报文段后进入CLOSE_WAIT状态（被动关闭），然后发送ACK确认，表示同意你关闭请求了，clien到server的数据链路关闭，client进入FIN_WAIT_2状态 
第三次挥手：client等待server发送完数据，server发送FIN到client请求关闭，server进入LAST_ACK状态
 
第四次挥手：client收到server发送的FIN后，回复ACK到server，client进入TIME_WAIT状态。server收到client的ACK后就关闭连接了，状态为CLOSED。client等待2MSL，仍然没有收到server的回复，说明client已经正常关闭了，client关闭连接。```


### TCP四次目的 
    为了让双方分别关闭自己的发送通道，确保所有数据都已安全传输和处理完毕，并通过 TIME_WAIT 防止旧报文影响新连接，实现可靠、有序的连接终止。


### 简单理解：
TCP属性全双工通信(接收和发送可以同时进行)，
client无数据发送时,向sever发送关闭信号，sever对其进行回应，但是sever这时还有数据发送，等sever不需要发送数据了，sever向client发送一个关闭信号。client接收到之后对其进行回应。这是client和sever的传输通道被关闭


## 问题1、为什么连接的时候是三次握手，关闭的时候却是四次握手？
答：因为当Server端收到Client端的SYN连接请求报文后，可以直接发送SYN+ACK报文。其中ACK报文是用来应答的，SYN报文是用来同步的。但是关闭连接时，当Server端收到FIN报文时，很可能并不会立即关闭SOCKET，所以只能先回复一个ACK报文，告诉Client端，"你发的FIN报文我收到了"。只有等到我Server端所有的报文都发送完了，我才能发送FIN报文，因此不能一起发送。故需要四步握手。

## 问题2、为什么TIME_WAIT状态需要经过2MSL(最大报文段生存时间)才能返回到CLOSE状态？

答： 1、保证自己发送的最后 ACK 能被对方收到（等待对方可能的 FIN 重传，最多 MSL 时间）
    2、让所有旧连接残留的报文在网络中过期（再等待 1×MSL）
    因此一共需要等待两个MSL。
    
> MSL: Maximum Segment Lifetime TCP 报文在网络中能存活的最长时间 (RFC 793 标准给了 2 分钟的参考值,UNIX是30s)

面试题：TCP和UDP的区别是什么？[TCP,UDP区别](https://zhuanlan.zhihu.com/p/24860273/)

连接方式：
- TCP 面向连接（三次握手）
- UDP 无连接（发了就走）

可靠性：
- TCP 有序、无丢包、不重复（ACK、重传、滑动窗口）
- UDP 不保证可靠性

速度：
- TCP 慢（确认、重传、流控）
- UDP 快（协议简单）

有序性：
- TCP 保证顺序
- UDP 不保证

流控/拥塞控制：
- TCP 有
- UDP 无（上层实现）

报文边界：
- TCP 无边界（流式）
- UDP 有边界（面向报文）

头部开销：
- TCP ≥ 20 字节
- UDP


