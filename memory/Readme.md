
# 内存管理


## 1、为什么要进行内存管理。

> 不同的系统版本对 App 运行时占用内存的限制不同，系统版本的升级也会增加占用的内存，同时 App 功能的增多也会要求越来越多的内存。然而，移动设备的内存资源是有限的，当 App 运行时占用的内存大小超过了限制后，就会被强杀掉，从而导致用户体验被降低。所以，为了提升 App 质量，开发者要非常重视应用的内存管理问题。


## 2、哪部分区域的内存管理需要我们管理 

答案： `堆`

如下图所示，内存主要分为4个部分：

![Block.jpg](https://upload-images.jianshu.io/upload_images/1846524-f6a8128e4ca85caf.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


1.代码区、静态区、常量区，程序运行时自动加载到内存中。堆区、栈区根据程序的代码分配内存。
2.除了堆区的内存，系统都会自动管理，不需要开发者操心。开发者关心的是如何对堆区的内存进行管理。

## 3、iOS 内存管理

堆中的内存是动态分配的，所以像C中 `malloc` `calloc` 和 iOS 中对象的创建 `alloc` 的对象都会放在堆中，因为是动态分配的，所以使用完毕之后要保证其释放，否则就会造成内存泄漏的问题。


在iOS中采用引用计数对内存进行管理。
引用计数是一种内存管理的方式，主要原理是：
当新建一个对象，或者有其他对象引用该对象时，引用计数器就会加1；当引用减少一次的时候，引用对象的计数器就会减1，当引用计数器为0时，系统会自动的回收这个对象所占用的内存。

iOS 内存管理 主要有MRC 和ARC:

MRC:手动引用计数，需要开发人员手动在合适的位置插入`retain`和`release`操作
ARC:自动引用计数，由编译器在合适的位置插入`retain`和`release`操作

即便是iOS采用了引用计数管理内存，但是还是不可避免的出现，对象无法释放的问题，即相互引用问题。

## 4、iOS 内存管理

### 4.1、`NSTimer`相互引用

如下代码段：

```ruby
@interface ViewController ()
@property (strong, nonatomic) NSTimer *timer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerTest) userInfo:nil repeats:YES];
}
```
上面的代码会产生循环引用问题，`self`（ViewController）引用`timer`, `timer` 又引用了`self`，所以会造成内存释放

解决：
 1、换用`NSTimer`的block方式
 
 ```ruby
 __weak typeof(self) weakSelf = self;
 self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
     [weakSelf timerTest];
 }];
```

2、引用中间层Proxy1

```
@interface Proxy : NSObject

+ (instancetype)proxyWithTarget:(id)target;

@property (weak, nonatomic) id target;

@end

@implementation Proxy

+ (instancetype)proxyWithTarget:(id)target {
    Proxy *proxy = [[Proxy alloc] init];
    proxy.target = target;
    return proxy;
}

// 需要指定谁来执行aSelector
- (id)forwardingTargetForSelector:(SEL)aSelector {
    return self.target;
}

@end

```

使用时

```ruby
self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:[Proxy proxyWithTarget:self] selector:@selector(timerTest) userInfo:nil repeats:YES];

```

2、引用更加高效的中间层Proxy

```
@interface Proxy : NSProxy

+ (instancetype)proxyWithTarget:(id)target;

@property (weak, nonatomic) id target;

@end

@implementation Proxy

+ (instancetype)proxyWithTarget:(id)target {
    Proxy *proxy = [[Proxy alloc] init];
    proxy.target = target;
    return proxy;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    return [self.target methodSignatureForSelector:sel];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    [invocation invokeWithTarget:self.target];
}

@end
```

类`Proxy`主要是用来消息转发的，直接进入消息转的第三步，越过了消息查找，和消息转发的前两步

`Proxy` 继承`NSProxy`, `Proxy` 继承`NSObject` 这样会有下面的差异点：

```
ViewController *vc = [[ViewController alloc] init];

Proxy *proxy1 = [Proxy proxyWithTarget:vc];

Proxy1 *proxy2 = [Proxy1 proxyWithTarget:vc];

NSLog(@"%d %d",
      [proxy1 isKindOfClass:[ViewController class]],
      
      [proxy2 isKindOfClass:[ViewController class]]);
}

打印结果: 1 0

解： 对于Proxy1它的父类是NSObject，所以不是ViewController的类及其子类
对于Proxy，由于继承NSProxy,所以直接进入消息转主，由target进行处理消息，而target正好是ViewController
```


### 4.1、`CADisplayLink`相互引用

`CADisplayLink`和`NSTimer`的target方法会出现同样的问题，


```ruby
@interface ViewController ()
@property (strong, nonatomic) CADisplayLink *link;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // 保证调用频率和屏幕的刷帧频率一致，60FPS
    self.link = [CADisplayLink displayLinkWithTarget:self selector:@selector(linkTest)];
    [self.link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
}

解决方案是使用中间层Proxy

self.link = [CADisplayLink displayLinkWithTarget:[Proxy proxyWithTarget:self] selector:@selector(linkTest)];

```

### 4.3、`GCD`定时器

NSTimer定时器依赖Runloop，当runloop任务比较重是，定时可能不准，而GCD不依赖runloop,是由系统提供

### 4.4、Tagged Pointer


从64bit开始，iOS引入了Tagged Pointer技术，用于优化NSNumber、NSDate、NSString等小对象的存储

在没有使用Tagged Pointer之前， NSNumber等对象需要动态分配内存、维护引用计数等，NSNumber指针存储的是堆中NSNumber对象的地址值

使用Tagged Pointer之后，NSNumber指针里面存储的数据变成了：Tag + Data，也就是将数据直接存储在了指针中

当指针不够存储数据时，才会使用动态分配内存的方式来存储数据

objc_msgSend能识别Tagged Pointer，比如NSNumber的intValue方法，直接从指针提取数据，节省了以前的调用开销

如何判断一个指针是否为Tagged Pointer？
iOS平台，最高有效位是1（第64bit）
Mac平台，最低有效位是1

### 4.5、引用计数

- 在iOS中，使用引用计数来管理OC对象的内存
- 一个新创建的OC对象引用计数默认是1，当引用计数减为0，OC对象就会销毁，释放其占用的内存空间
- 调用retain会让OC对象的引用计数+1，调用release会让OC对象的引用计数-1

内存管理的经验总结：

    当调用alloc、new、copy、mutableCopy方法返回了一个对象，在不需要这个对象时，要调用release或者autorelease来释放它
    想拥有某个对象，就让它的引用计数+1；不想再拥有某个对象，就让它的引用计数-1

可以通过以下私有函数来查看自动释放池的情况
extern void _objc_autoreleasePoolPrint(void);


### 4.6、引用计数的存储

在64bit中，引用计数可以直接存储在优化过的isa指针中，也可能存储在SideTable类中
