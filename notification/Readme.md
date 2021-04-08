
# Notification简介

### 1、Notification的概念

> `通知`是发送给一个或多个观察对象的消息，用于通知它们程序中的事件。`Cocoa`框架中的通知采用的是广播的方式。事件的接收者被称为`观察者`，它可以根据相应的事件来改变自己的`外观`、`行为`和`状态`。发送者只需关心发送的消息，并不需要知道观察者是谁。因此，通知是一种在程序中实现协调和内聚的强大机制。

通知的大致流程如下图所示：

![notificationcenter_2x.png](https://upload-images.jianshu.io/upload_images/1846524-2c2f21032290df2c.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

- 对象将消息发送给`NSNotificationCenter`，`NSNotificationCenter`再将消息广播给`观察者`。

### 2、Notification涉及的对象

#### 2.1、Notification 消息
OC中的消息体在Swift中如下声明，其中`name` 、`object` 、`userInfo`都是只读的，只能通过初始化方法设定初始化值。
```python
open class NSNotification : NSObject, NSCopying, NSCoding {

    open var name: NSNotification.Name { get }

    open var object: Any? { get }

    open var userInfo: [AnyHashable : Any]? { get }

    @available(iOS 4.0, *)
    public init(name: NSNotification.Name, object: Any?, userInfo: [AnyHashable : Any]? = nil)

    public init?(coder: NSCoder)
}
```
但是在Swift中，又为`NSNotification`包裹了一层，其声明如下：
```python
public struct Notification : ReferenceConvertible, Equatable, Hashable {

public typealias ReferenceType = NSNotification

/// A tag identifying the notification.
public var name: Notification.Name

/// An object that the poster wishes to send to observers.
///
/// Typically this is the object that posted the notification.
public var object: Any?

/// Storage for values or objects related to this notification.
public var userInfo: [AnyHashable : Any]?

/// Initialize a new `Notification`.
///
/// The default value for `userInfo` is nil.
public init(name: Notification.Name, object: Any? = nil, userInfo: [AnyHashable : Any]? = nil)

```
可见`name` 、`object` 、`userInfo`变成了可读可写的了。但是`Notification`内部还是使用的`NSNotification`

属性解释
- name: 通知的标识
- object: 发送者想要发送给观察者的对象，通常是发送者本身
- userInfo: 当前通知要发送的信息


#### 2.2、NSNotificationCenter 

通知中心本质上是一个消息调度表，当一个事件发生之后，就会把相应的消息发送给相应的观察对象。通知中心的目的就是为相互不知道对方存在但是需要交流的对象之间提供一种通信的方式。

`NotificationCenter`提供的方式大致如下,主要包括添加/移除观察者和发送消息。另外通知中心采用的是一个单例的形式，不需要额外创建。

```python
open class NotificationCenter : NSObject {

    
    open class var `default`: NotificationCenter { get }

    
    open func addObserver(_ observer: Any, selector aSelector: Selector, name aName: NSNotification.Name?, object anObject: Any?)

    
    open func post(_ notification: Notification)

    open func post(name aName: NSNotification.Name, object anObject: Any?)

    open func post(name aName: NSNotification.Name, object anObject: Any?, userInfo aUserInfo: [AnyHashable : Any]? = nil)

    
    open func removeObserver(_ observer: Any)

    open func removeObserver(_ observer: Any, name aName: NSNotification.Name?, object anObject: Any?)

    
    @available(iOS 4.0, *)
    open func addObserver(forName name: NSNotification.Name?, object obj: Any?, queue: OperationQueue?, using block: @escaping (Notification) -> Void) -> NSObjectProtocol
}
```
#### 2.3、NSNotificationQueue 

```python
open class NotificationQueue : NSObject {

    
    open class var `default`: NotificationQueue { get }

    
    public init(notificationCenter: NotificationCenter)

    
    open func enqueue(_ notification: Notification, postingStyle: NotificationQueue.PostingStyle)

    open func enqueue(_ notification: Notification, postingStyle: NotificationQueue.PostingStyle, coalesceMask: NotificationQueue.NotificationCoalescing, forModes modes: [RunLoop.Mode]?)

    
    open func dequeueNotifications(matching notification: Notification, coalesceMask: Int)
}
```
`NSNotificationQueue`其实就是一个消息队列，它是通知中心的一个消息缓存区。消息队列保存消息，消息的转发采用`FIFO`的顺序。 默认情况下，每个线程的消息会集中到对应的默认消息队列中,即`NotificationQueue.default`。通过`post`的方式发送消息是同步的，即`post`之后的代码只能等到发送的消息被执行完成之后才能继续执行；通过`enqueue`的方式发送消息是异步的。

`NSNotificationQueue`的两个重要的特征是：`消息合并`和`异步发送`

消息合并涉及`NotificationQueue.NotificationCoalescing` Set类型,

- none：不合并队列中的消息
- onName：合并`NSNotification.Name`的相同的消息
- onSender：合并`object`的相同的消息

异步发送涉及 `NotificationQueue.PostingStyle`枚举类型，发送的方式包括：

- whenIdle：当runloop处于空闲状态时发送通知
- asap：在当前通知调用结束或计时器超时发送通知
- now：在合并通知后立即发送通知

#### 2.4、Observer 

观察者

`NSNotificationCenter`提供两个的`addObserver`方法中，其中`open func addObserver(forName name: NSNotification.Name?, object obj: Any?, queue: OperationQueue?, using block: @escaping (Notification) -> Void) -> NSObjectProtocol` 方法中的 queue为回调的执行队列


### 3、GNU Notification实现原理

GNU提供了一套`Notification`的实现方法，其中一个通知中心（`NCTbl-->NotificationCenterTable`）的数据结构如下所示：

```python
typedef struct NCTbl {
  Observation        *wildcard;    /* Get ALL messages.        */
  GSIMapTable        nameless;    /* Get messages for any name.    */
  GSIMapTable        named;        /* Getting named messages only.    */
  unsigned        lockCount;    /* Count recursive operations.    */
  NSRecursiveLock    *_lock;        /* Lock out other threads.    */
  Observation        *freeList;
  Observation        **chunks;
  unsigned        numChunks;
  GSIMapTable        cache[CACHESIZE];
  unsigned short    chunkIndex;
  unsigned short    cacheIndex;
} NCTable;

```
因为添加观察者(`addObserver`)的时候 `name` 和`object`都是可选的，所以 `NCTbl`将三种可能情况都进行了考虑：
一是`name`和`object`都不存在，这时所有的观察者都放入了`wildcard`中
二是`name`存在，后续的操作都放入到`named`中（这里会包括`object`不存在的情况）
三是`name`不存在，后续的操作都放入到`nameless`中

第一、二种情况的结构展示如下图：

![Notification GNU.jpg](https://upload-images.jianshu.io/upload_images/1846524-978fd2fa5630b2f9.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

第三种情况的结构展示如下图：
![Notification GNU-NAMELESS.jpg](https://upload-images.jianshu.io/upload_images/1846524-dbbefa7b0b879cfb.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


观察者链表结点的结构如下：

```python
typedef struct Obs {
  id        observer;    /* Object to receive message.    */
  SEL        selector;    /* Method selector.        */
  struct Obs    *next;        /* Next item in linked list.    */
  int        retained;    /* Retain count for structure.    */
  struct NCTbl    *link;        /* Pointer back to chunk table    */
} Observation;

```


## 参考文档

[Notification](https://developer.apple.com/library/archive/documentation/General/Conceptual/DevPedia-CocoaCore/Notification.html#//apple_ref/doc/uid/TP40008195-CH35-SW1)
[NSNotificationCenter](https://developer.apple.com/library/archive/documentation/LegacyTechnologies/WebObjects/WebObjects_3.5/Reference/Frameworks/ObjC/Foundation/Classes/NSNotificationCenter/Description.html#//apple_ref/occ/cl/NSNotificationCenter)
[NSNotificationQueue](https://developer.apple.com/library/archive/documentation/LegacyTechnologies/WebObjects/WebObjects_3.5/Reference/Frameworks/ObjC/Foundation/Classes/NSNotificationQueue/Description.html#//apple_ref/occ/cl/NSNotificationQueue)

