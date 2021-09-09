
# AutoreleasePool

## 1、内存管理
这是Objective C通过引用计数来管理内存的一种方式，
MRC为手动引用计数，
ARC为自动引用计数，
autorelease则是添加到自动释放池中。

1、ARC和MRC的区别：ARC相对于MRC，不需要手动书写retain/release/autorelease，而是在编译期和运行期这两部分帮助开发者管理内存。

在编译的时候，ARC调用C接口实现的retain/release/autorelease，在运行期的时候使用runtime配合来实现内存管理。

2、autorelease分为两种情况：手动干预释放时机、系统自动释放。

手动干预释放机制：指定autoreleasepool，就是所谓的作用域大括号结束释放；
系统自动释放：不手动指定autoreleasepool。
autorelease对象除了作用域后，会被添加到最近一次创建的自动释放池中，并会在当前的runloop迭代结束时释放。

ps:runloop从程序启动到加载完成是一个完整的运行循环，然后会停下来，等待用户交互，用户的每一次交互都会启动一次运行循环，这时候会创建自动释放池，来处理用户所有的点击事件、触摸事件，在一次完整的运行循环结束之前，会销毁自动释放池，达到销毁对象的目的。


使用以下名称开头的方法名意味着自己生成的对象自己持有：

    alloc
    new
    copy
    mutableCopy
    
除了以上四种方式创建的对象，都不是自己持有的

    id obj = [NSMutableArray array];//自己不持有
    [UIImage imageNamed:@"test"];//自己不持有
    


## 2、AutoreleasePool概念

自动释放池的主要底层数据结构是：__AtAutoreleasePool、AutoreleasePoolPage

调用了autorelease的对象最终都是通过AutoreleasePoolPage对象来管理的


创建和释放 

App启动后，苹果在主线程 RunLoop 里注册了两个 Observer，其回调都是 _wrapRunLoopWithAutoreleasePoolHandler()。 
第一个 Observer 监视的事件是 Entry(即将进入Loop)，其回调内会调用 _objc_autoreleasePoolPush() 创建自动释放池。其 order 是-2147483647，优先级最高，保证创建释放池发生在其他所有回调之前。 
第二个 Observer 监视了两个事件： BeforeWaiting(准备进入休眠) 时调用_objc_autoreleasePoolPop() 和 _objc_autoreleasePoolPush() 释放旧的池并创建新池；Exit(即将退出Loop) 时调用 _objc_autoreleasePoolPop() 来释放自动释放池。这个 Observer 的 order 是 2147483647，优先级最低，保证其释放池子发生在其他所有回调之后。 
在主线程执行的代码，通常是写在诸如事件回调、Timer回调内的。这些回调会被 RunLoop 创建好的 AutoreleasePool 环绕着，所以不会出现内存泄漏，开发者也不必显示创建 Pool 了。 
也就是说AutoreleasePool创建是在一个RunLoop事件开始之前(push)，AutoreleasePool释放是在一个RunLoop事件即将结束之前(pop)。 

AutoreleasePool里的Autorelease对象的加入是在RunLoop事件中，AutoreleasePool里的Autorelease对象的释放是在AutoreleasePool释放时。
