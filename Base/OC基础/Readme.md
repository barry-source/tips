
### 1. 写一个setter方法用于完成@property （nonatomic, retain）NSString *name,
写一个setter方法用于完成@property（nonatomic，copy）NSString *name.

解：考查MRC下属性的基本用法 

```ruby

@property (nonatomic, retain) NSString *name;

对应setter

- (void)setName:(NSString *)name {
    if (_name == name) {
        [_name release];
        _name = [name retain];
    }
}

@property (nonatomic, copy) NSString *name;

对应setter

- (void)setName:(NSString *)name {
    if (_name != name) {
        [_name release];
        _name = [name copy];
    }
    return _name;
}

```

### 2、下面代码段的打印结果

```ruby
    NSMutableArray *array = [NSMutableArray array];
    NSString *string = [NSString stringWithFormat:@"test"];
    [string retain];
    [array addObject:string];
    NSLog(@"%ld", string.retainCount);
    [string retain];
    [string release];
    [string release];
    NSLog(@"%ld", string.retainCount);
    [array removeAllObjects];
    NSLog(@"%ld", string.retainCount);
```

解：因为`string`是字符串，字符串在常量区，没有引用计数, 打印结果都为-1（表示无限大）

```ruby
2021-07-30 14:56:08.576726+0800 TestOc[35416:5352642] -1
2021-07-30 14:56:08.576870+0800 TestOc[35416:5352642] -1
2021-07-30 14:56:08.576974+0800 TestOc[35416:5352642] -1
```

### 3、关键字const是什么含义

```ruby
1---> const int a;  
2---> int const a;  
3---> const int * a; 
4---> int const * a;  
5---> int * const a;  
6---> int const * const a;
```

解：快速方法分析，对于所有的const修饰的变量，先将类型去掉，结果如下：

```ruby
1---> const a;  
2---> const a;  
3---> const * a; 
4---> const * a;  
5---> * const a;  
6---> const * const a;
```
分析可知： 
1 和 2 是一样的，表示定义一个整型常量
3 和4 是一样的，表示定义一个指向整型的指针，`const * a` 不可通过指针（`*a`）修改指向的值，但是 `a`可以指向其它整型变量
5 表示指向整型变量的常量指针,`* const a` const 限定 指针 `a`，指针不可指向其它整型变量，但是可以通过指针`*a`修改指向的值
6 表示一个指向常整型数的常量指针，既不可能通过指针修改指向的值，指针的指向也不可改变

### 4、 define 和 const常量有什么区别?

- define 在`预处理`(预编译)阶段进行替换，const 常量在`编译`阶段使用
- 宏不做类型检查，仅仅进行替换，const 常量有数据类型，会执行类型检查
- define 不能调试，const 常量可以调试
- define 定义的常量在替换后运行过程中会不断地占用内存，而 const 定义的常量存储在数据段只有一份 copy，效率更高
- define 可以定义一些简单的函数，const 不可以

### 5、static的作用？

- static修饰的函数是一个内部函数，只能在本文件中调用，其他文件不能调用
- static修饰的全部变量是一个内部变量，只能在本文件中使用，其他文件不能使用
- static修饰的局部变量只会初始化一次，并且在程序退出时才会回收内存

### 6、堆和栈的区别

从管理方式来讲

    对于栈来讲，是由编译器自动管理，无需我们手工控制；

    对于堆来说，释放工作由程序员控制，容易产生内存泄露(memory leak)

从申请大小方面讲

    栈空间比较小

    堆空间比较大

从数据存储方面来讲

    栈空间中一般存储基本类型，对象的地址

    堆空间一般存放对象本身，block 的 copy 等

### 7 进程线程的区别：

进程：是并发执行的程序在执行过程中分配和管理资源的基本单位，是一个动态概念，竞争计算机系统资源的基本单位（包工头）。

线程：是进程的一个执行单元，是进程内调度实体（工人）。比进程更小的独立运行的基本单位。线程也被称为轻量级进程。

一个程序至少一个进程，一个进程至少一个线程。

地址空间：同一进程的线程共享本进程的地址空间，而进程之间则是独立的地址空间。
资源拥有：同一进程内的线程共享本进程的资源如内存、I/O、cpu等，但是进程之间的资源是独立的。
　　　　　一个进程崩溃后，在保护模式下不会对其他进程产生影响，但是一个线程崩溃整个进程都死掉。所以多进程要比多线程健壮。

　　　　　进程切换时，消耗的资源大，效率高。所以涉及到频繁的切换时，使用线程要好于进程。同样如果要求同时进行并且又要共享某些变量的并发操作，只能用线程不能用进程

执行过程：每个独立的进程程有一个程序运行的入口、顺序执行序列和程序入口。但是线程不能独立执行，必须依存在应用程序中，由应用程序提供多个线程执行控制。
线程是处理器调度的基本单位，但是进程不是。
两者均可并发执行。

### 7、@property 的本质是什么？

@property = ivar(实例变量) + getter + setter;

@property 其实就是在编译阶段由编译器自动帮我们生成 ivar 成员变量，getter 方法，setter 方法

但是在分类中并不能生成`ivar`成员变量，这是分类为什么不能增加属性的原因 

### 8、沙盒目录结构是怎样的？各自用于那些场景？

- Documents
- Library
    - Cache
    - Preferences 
- tmp

※Documents

保存用户创建的文档文件的目录，用户可以通过文件分享分享该目录下的文件。在iTunes和iCloud备份时会备份该目录。建议保存你希望用户看得见的文件。

※Library

苹果不建议在该目录下保存任何用户相关数据，而是保存APP运行需要的修改数据，当然用户可以根据自己的实际需要进行保存。
该目录下默认有两个子目录，为Caches、Preferences。根据文档还有另外两个系统预存放文件的子目录，分别是Application Support、Frameworks。用户还可以自己根据需要创建相应的目录。该目录下除Caches目录外，在iTunes和iCloud备份时会备份除Caches目录外的其他所有目录。四个目录的预定义如下：
    Cache：建议保存数据缓存使用。在用户的磁盘空间已经使用完毕时有可能删除该目录下的文件，在APP使用期间不会删除，APP没有运行时系统有可能进行删除。需要持久化的数据建议不要保存在该目录下，以免系统强制删除。

   Preferences：用户偏好存储目录，在使用NSUserDefaults或者CFPreferences接口保存的数据保存在该目录下，编程人员不需要对该目录进行管理。在iTunes和iCloud备份时会备份该目录。
※tmp

苹果建议该目录用来保存临时使用的数据，编程人员应该在数据长时间内不使用时主动删除该目录下的文件，在APP没有运行期间，系统可能删除该目录下的文件。在iTunes和iCloud备份时不会备份该目录。

### 9、volatile
volatile是一个特征修饰符,volatile的作用是作为指令关键字，确保本条指令不会因编译器的优化而省略，且要求每次直接读值。

volatile应该解释为“直接存取原始内存地址”比较合适

### 10、对于语句NSString*obj = [[NSData alloc] init]; ，编译时和运行时obj分别是什么类型？
解：编译时是NSString类型，运行时是NSData类型

### 11. #import 跟#include、@class有什么区别？#import<> 跟 #import""又什么区别？
都可以完整包含某个文件的内容，但是#import能防止一个文件被包含多次
@class仅仅是声明一个类名，并不会包含类的完整声明；@class还能解决循环包含的问题
#import<> 用来包含系统自带的文件，#import""用来包含自定义的文件

### 12、 属性readwrite，readonly，assign，retain，copy，nonatomic 各是什么作用，在那种情况下用？
- readwrite：同时生成get方法和set方法的声明和实现
- readonly：只生成get方法的声明和实现
- assign：set方法的实现是直接赋值，用于基本数据类型
- retain：set方法的实现是release旧值，retain新值，用于OC对象类型
- copy：set方法的实现是release旧值，copy新值，用于NSString、block等类型
- nonatomic：非原子性，set方法的实现不加锁（比atomic性能高）

### 13. What is advantage of categories? What is difference between implementing a category and inheritance?
- 分类可以在不修改原来类模型的基础上拓充方法
- 分类只能扩充方法、不能扩充成员变量；继承可以扩充方法和成员变量
- 继承会产生新的类

### 14. Difference between categories and extensions?
- 分类是有名称的，类扩展没有名称
- 分类只能扩充方法、不能扩充成员变量；类扩展可以扩充方法和成员变量
- 类扩展一般就写在.m文件中，用来扩充私有的方法和成员变量（属性）


### 18. When we call Objective-C is runtime language what does it mean?
- 动态绑定：对象类型在运行时才真正确定
- 多态性
- 消息机制

### 19、OC消息机制

发送消息步骤：

- 消息查找
- 消息转发
    - 动态方法解析
    - 消息转发给某一个的target
    - 再次消息转发



![image.png](https://upload-images.jianshu.io/upload_images/1846524-35a99eba8965d30f.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

### 20、 How many autoreleasepool you can create in your application? Is there any limit?
没有限制

### 21. self.跟self->什么区别？
`self.`是调用get方法或者set方法, 这是OC的操作

OC对象的底层就是一个结构体，而平时使用时都是定义一个对象指针，也即结构体指针。
`self`是当前本身，是一个指向当前对象的指针, 
`self->`是直接访问成员变量


### 22、 nil、Nil、NULL和NSNull

- NULL 表示一个空指针, (stddef.h 文件中的定义 define NULL ((void*)0))
- 
- nil一般赋值给空对象；（objc.h 有定义 ，其它本质上和NULL相同）

- Nil 用于表示Objective-C类（Class）类型的变量值为空

- NSNull 表示OC中的空对象


### 23. What is predicate?

OC中的谓词操作是针对于数组类型的，他就好比数据库中的查询操作，数据源就是数组，这样的好处是我们不需要编写很多代码就可以去操作数组，同时也起到过滤的作用，我们可以编写简单的谓词语句，就可以从数组中过滤出我们想要的数据。

### 24. OC和swift 的存取权限

OC 严格来说没有私有变量， @private修饰的变量可以通过runtime进行修改, kvc 

OC:

- @public : 所有的类都可以访问
- @private : 只有当前类可以访问
- @protected : （默认） 当前类和子类可访问
- @package： 对于framework内部是@protected的权限，对于外部的类是@private，相当于框架级的保护权限，适合使用在静态库.a中

@public > (@package，@protected) > @private


Swift：

- open : 可以在任何地方访问、继承和重写
- public: 可以在任何地方被访问, 不可继承
- interal: 默认访问级别，在整个模块内都可以被访问
- private: 其修饰的属性和方法只能在本类被访问和使用，不包括扩展类
- fileprivate:  其修饰的属性可以再同一个文件被访问、继承和重写

### 25、 控制器生命周期

1：initialize函数并不会每次创建对象都调用，只有在这个类第一次创建对象时才会调用，

2：init方法和initCoder方法相似，只是被调用的环境不一样，如果用代码进行初始化，会调用init，从nib文件或者归档进行初始化，会调用initCoder。

3：loadView方法是开始加载视图的起始方法，除非手动调用，否则在ViewController的生命周期中没特殊情况只会被调用一次。

4：viewDidLoad方法是我们最常用的方法的，类中成员对象和变量的初始化我们都会放在这个方法中，在类创建后，无论视图的展现或消失，这个方法也是只会在将要布局时调用一次。

5：viewWillAppare：视图将要展现时会调用。

6：viewWillLayoutSubviews：在viewWillAppare后调用，将要对子视图进行布局。

7：viewDidLayoutSubviews：已经布局完成子视图。

8：viewDidAppare：视图完成显示时调用。

9：viewWillDisappare：视图将要消失时调用。

10：viewDidDisappare：视图已经消失时调用。

11：dealloc：controller被释放时调用。


### 26、懒汉模式和饿汉模式

懒汉式在类加载时不初始化，延迟加载。（配置文件），懒汉式需要加synchronized，否则不安全。(alloc时才分配)
饿汉式在类加载时初始化，加载慢，获取对象快。饿汉式是线程安全的，(load时分配)

### 27、Swift 和OC对比

1）Swift是强类型（静态）语言，有类型推断，Objective-C弱类型（动态）语言
2）Swift面向协议编程，Objective-C面向对象编程
3）Swift注重值类型，Objective-C注重引用类型
4）Swift支持泛型，Objective-C只支持轻量泛型（给集合添加泛型）
5）Swift支持静态派发（效率高）、动态派发（函数表派发、消息派发）方式，Objective-C支持动态派发（消息派发）方式
6）Swift支持函数式编程（高阶函数）
7）Swift的协议不仅可以被类实现，也可以被Struct和Enum实现
8）Swift有元组类型、支持运算符重载
9）Swift支持命名空间
10）Swift支持默认参数
11）Swift比Objective-C代码更简洁

### 28、讲讲Swift的派发机制

1）函数的派发机制：静态派发（直接派发）、函数表派发、消息派发

2）Swift派发机制总结：

    Swift中所有ValueType（值类型：Struct、Enum）使用直接派发；
    Swift中协议的Extensions使用直接派发，初始声明函数使用函数表派发；
    Swift中Class中Extensions使用直接派发，初始声明函数使用函数表派发，dynamic修饰的函数使用消息派发；
    Swift中NSObject的子类用@nonobjc或final修饰的函数使用直接派发，初始声明函数使用函数表派发，dynamic修饰的Extensions使用消息派发；
    
3）Swift中函数派发查看方式: 可将Swift代码转换为SIL（中间码）

    swiftc -emit-silgen -O example.swift


### 29、Swift如何显示指定派发方式？

    添加final关键字的函数使用直接派发
    添加static关键字函数使用直接派发
    添加dynamic关键字函数使用消息派发
    添加@objc关键字的函数使用消息派发
    添加@inline关键字的函数会告诉编译器可以使用直接派发
