
### 1、 CoreGraphics框架里申请的内存忘记释放

### 2、CF层的东西申请一定要释放  

### 3、delegate 使用 strong修饰造成循环引用

### 4、NSTimer 不正确使用造成的内存泄漏， 

    1、设置为NO的时候，不会引起内存泄漏
    2、设置为YES的时候，有执行invalidate就不会内存泄漏，没有执行invalidate就会内存泄漏，在 timer的执行方法里调用invalidate也可以。
    
    3、中间target：控制器无法释放，是因为timer对控制器进行了强引用，使用类方法创建的timer默认加入了runloop，所以，timer只要不持有控制器，控制器就能释放了。

### 5、block 造成的内存泄漏

block为了保证代码块内部对象不被提前释放，会对block中的对象进行强引用，就相当于持有了其中的对象，而如果此时block中的对象又持有了该block，就会造成循环引用。

但不是所有的block都会造成循环引用。masonry 就不会，因为是同步操作

### 6、UIWebView
    UIWebView 内存问题应该是众所周知了吧，Apple官方也承认了内存泄露确实存在，
    所以在 iOS8 推出了功能和性能都更加强大WKWebView。

### 7、WKWebView
    
    
    addScriptMessageHandler 时要记得移除





