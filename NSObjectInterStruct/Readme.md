
# NSObject内部构造

### 1、Objective-C中对象分为三类：分别是实例对象，类对象和元类对象。可以通过以下方式获取。

- 实例对象：通过 `alloc` 、`init`的方式返回的就是一个实例对象。
- 类对象：通过runtime中的方法 `object_getClass`,传入一个**实例**对象，获取的是一个类对象。（类对象的获取也可以通过实例对象调用 `class`方法的方式或类名调用类方法`class`的方式。）
- 元类对象： 通过runtime中的方法 `object_getClass`,传入一个**类**对象，获取的是一个元类对象。(只能通过此方法获取元类对象)

#### 示例代码1：
```Objective-C
//获取实例对象
NSObject *obj1 = [[NSObject alloc] init];
NSObject *obj2 = [[NSObject alloc] init];
//获取类对象
Class cls1 = object_getClass(obj1);
Class cls2 = object_getClass(obj2);
Class cls3 = [obj1 class];
Class cls4 = [NSObject class];
//获取元类对象
Class m1 = object_getClass(cls1);
Class m2 = object_getClass(cls2);
NSLog(@"实例对象地址：%p--%p", obj1, obj2);
NSLog(@"类对象地址：%p--%p--%p--%p", cls1, cls2, cls3, cls4);
NSLog(@"元类对象地址：%p--%p", m1, m2);
```
上述代码的打印结果为：
```
实例对象地址：0x1004a14b0--0x1004a0570
类对象地址：0x7fff980f8118--0x7fff980f8118--0x7fff980f8118--0x7fff980f8118
元类对象地址：0x7fff980f80f0--0x7fff980f80f0
```

- 注：不管是实例对象的`class`方法和类对象的`class`方向最后返回的都是类对象，为什么？这个问题看下源码就知道了。

```Objective-C
// 类对象的class调用直接返回自身
+ (Class)class {
    return self;
}

// 实例对象的class调用，利用的是object_getClass，因为传入的是一个实例对象，所以返回的是类对象
- (Class)class {
    return object_getClass(self);
}
```
### 2、三种对象存放的信息

由上可知，类对象和元类对象的类型都是**Class**, 先看下**Class**里面包含什么内容。对于旧版本的结构体定义，在`runtime.h`中,  `typedef struct objc_class *Class`由此知，**Class **是 `struct objc_class *`的别名。
旧版本`objc_class`结构体的形式如下：
```
struct objc_class {
    Class _Nonnull isa  OBJC_ISA_AVAILABILITY;
    // 以下的定义在__OBJC2__中已经不可使用
    #if !__OBJC2__
    Class _Nullable super_class                              OBJC2_UNAVAILABLE;
    const char * _Nonnull name                               OBJC2_UNAVAILABLE;
    long version                                             OBJC2_UNAVAILABLE;
    long info                                                OBJC2_UNAVAILABLE;
    long instance_size                                       OBJC2_UNAVAILABLE;
    struct objc_ivar_list * _Nullable ivars                  OBJC2_UNAVAILABLE;
    struct objc_method_list * _Nullable * _Nullable methodLists                    OBJC2_UNAVAILABLE;
    struct objc_cache * _Nonnull cache                       OBJC2_UNAVAILABLE;
    struct objc_protocol_list * _Nullable protocols          OBJC2_UNAVAILABLE;
    #endif

} OBJC2_UNAVAILABLE;
/* Use `Class` instead of `struct objc_class *` */
```

虽然已然不可使用，但从其中大致可以看到Class中包含的一些信息。主要包含以下几点

-  isa 指针
- super_class 指针
- 成员变量信息  ivars
- 方法信息 methodLists（实例对象方法和类对象方法）
- 协议信息 protocols
- 缓存信息  cache

由**示例代码1**的打印结果来看，类对象和元类对象，不管获取多少次或者通过不同的对象参数获取 最终地址都是唯一的，也就是类对象和元类对象在内存中只有一份。
实例对象 每次创建都会分配一个新的地址。

#### 实例对象主要包含的信息：
-  isa 指针
- 成员变量

#### 类对象主要包含的信息：
-  isa 指针
- super_class 指针
- 成员变量列表  ivars
- 实例对象方法 methodLists
- 协议 protocols
- 缓存 cache

#### 元类对象主要包含的信息：
-  isa 指针
- super_class 指针
- 类对象方法 methodLists
- 缓存 cache

### 3、isa 和super_class 指向
三种对象的内部构造中都包含了一个**isa**指针。**isa**指针有什么作用？
- 实例对象的**isa**指针指向它的类对象，类对象描述实例对象的数据（分配的空间大小，变量类型和布局）和行为（响应的selector和实现的实例方法）
- 类对象的**isa**指针指向它的元类对象，元类对象是对类对象的描述，其中包括类方法等。
- 元类对象的**isa**指针指向根元类对象，根元类对象的**isa**指针指向它自己，形成了一个闭环。

### super_class 指向
`super_class `是类继承的桥梁。通过和`isa`的配合，可以实现子类调用父类中的方法等。

- `super_class `指针只存在于`Class`类型中，也就是说只存在于类对象和元类对象中。
- 类对象的`super_class `指向它的父类的类对象，父类的`super_class `指向根类的类对象，根类的`super_class `为nil
- 元类对象的`super_class `指向它的父类的元类对象，父类的`super_class `指向根类的元类对象，根类的`super_class `指向的是根类的类对象**（这块比较特殊）**


####  isa和super_class整体指向流程

![经典图片,一图胜万言](https://upload-images.jianshu.io/upload_images/1846524-10db010c7ab34c79.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

### 4、NSObject 实际存储结构



## 参考文档

[类对象和元类对象](http://www.sealiesoftware.com/blog/archive/2009/04/14/objc_explain_Classes_and_metaclasses.html)
