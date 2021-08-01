
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

![image.png](https://upload-images.jianshu.io/upload_images/1846524-35a99eba8965d30f.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

33. How many autoreleasepool you can create in your application? Is there any limit?
没有限制





