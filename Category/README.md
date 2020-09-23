### 面试题

> Category的实现原理，Category能不能加属性。如果不能，为什么？

> Category中有load方法吗？load方法的调用时机？load 方法能继承吗？

> load、initialize在category中的调用的顺序，以及出现继承时他们之间的调用的过程

> load、initialize的区别，以及它们在category重写的时候的调用的次序。


```Objective-C

/// Animal.h
@interface Animal : NSObject

- (void)run;

@end

/// Animal.m

@implementation Animal

- (void)run {
    NSLog(@"Animal --- run");
}

@end

///  Animal+Function1.h

@interface Animal (Function1) <NSCopying>

@property (nonatomic, assign) NSInteger age;

- (void)animalInstanceMethod;
+ (void)animalClassMethod;

@end

///  Animal+Function1.m

#import "Animal+Function1.h"

@implementation Animal (Function1)

- (void)run {
    NSLog(@"Function1 --- run");
}

- (void)animalInstanceMethod {
    NSLog(@"Function1 --- animalInstanceMethod");
}

+ (void)animalClassMethod {

}

- (NSInteger)age {
    return 10;
}

- (void)setAge:(NSInteger)age {

}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return [Animal new];
}

@end

///  Animal+Function2.h

@interface Animal (Function2)

@end

///  Animal+Function2.m

@implementation Animal (Function2)

- (void)run {
    NSLog(@"Function2 --- run");
}

@end

```

## 一、Category的实现原理

#### 1.1、Category的底层构造

先从源码[objc4-781](https://opensource.apple.com/tarballs/objc4/)中找出分类的定义，其构造如下：

```Objective-C
struct category_t {
    const char *name;   // 所属类的名字，通俗说就是谁的分类，这里就是谁的名字
    classref_t cls;     //
    struct method_list_t *instanceMethods;      // 实例方法列表
    struct method_list_t *classMethods;         // 类方法列表
    struct protocol_list_t *protocols;          // 协议方法列表
    struct property_list_t *instanceProperties; // 实例属性列表
    // Fields below this point are not always present on disk.
    struct property_list_t *_classProperties;   // 类实例属性列表（目前没有）

    method_list_t *methodsForMeta(bool isMeta) {// 如果是元类返回类方法列表，否则返回实例方法列表
        if (isMeta) return classMethods;
        else return instanceMethods;
    }

    property_list_t *propertiesForMeta(bool isMeta, struct header_info *hi);

    protocol_list_t *protocolsForMeta(bool isMeta) {// 如果是元类返回空(类协议目前不存在)，否则返回实例协议方法列表
        if (isMeta) return nullptr;
        else return protocols;
    }
};
```

然后利用命名将*Animal+Function1.m*分类文件转换成底层c++文件，内部可发现相应的分类定义，其构造如下：

```Objective-C
struct _category_t {
    const char *name;
    struct _class_t *cls;
    const struct _method_list_t *instance_methods;
    const struct _method_list_t *class_methods;
    const struct _protocol_list_t *protocols;
    const struct _prop_list_t *properties;
};
```

对比之下发现少了部分，这不重要，命令生成的不是最新的形式，只是帮助我们来研究相应的一些内容。

下面先简单介绍一部分类型，以便理清分类的整体实现构造。
利用命令生成的代码名会比源码中找到的会多出个下划线（比如 iOS的私有类名就会以下划线开头）

- *objc_method*的定义

源码：

```Objective-C
struct objc_method {
    SEL _Nonnull method_name                                 OBJC2_UNAVAILABLE;
    char * _Nullable method_types                            OBJC2_UNAVAILABLE;
    IMP _Nonnull method_imp                                  OBJC2_UNAVAILABLE;
}                                                            OBJC2_UNAVAILABLE;
```

命令生成：

```Objective-C
struct _objc_method {
    struct objc_selector * _cmd;
    const char *method_type;
    void  *_imp;
};
```

```Objective-C
objc_selector * 和 SEL 是等价的，其源码描述如下：

/// An opaque type that represents a method selector.
typedef struct objc_selector *SEL; 
```

类型*objc_selector*源码中没有给出具体的实现，但是从[GNU](http://www.gnustep.org/resources/downloads.php)中有大致的相关实现，以供参考。

GNU中*objc_selector*定义如下：

```Objective-C
/**
* Structure used to store selectors in the list.
*/
struct objc_selector
{
    union
    {
        /**
        * The name of this selector.  Used for unregistered selectors.
        */
        const char *name;
        /**
        * The index of this selector in the selector table.  When a selector
        * is registered with the runtime, its name is replaced by an index
        * uniquely identifying this selector.  The index is used for dispatch.
        */
        uintptr_t index;
    };
    /**
    * The Objective-C type encoding of the message identified by this selector.
    */
    const char * types;
};
```

在iOS平台定义可能不同，**暂时可以将SEL看成char *类型**，原因如下：

```Objective-C
SEL selector = @selector(animalClassMethod);
NSLog(@"%s", selector);
/// 输出结果：animalClassMethod
```

首先SEL是一个结构体，如果直接打印结构体将会打印第一个成员变量。以GNU 中*objc_selector*的定义为例,验证如下：

```Objective-C
struct objc_selector *s = {{"firstVar"}, 100};
NSLog(@"%s", s);
/// 输出结果：firstVar
```

IMP 就是一个函数指针，其在源码中的定义如下：

```Objective-C
typedef void (*IMP)(void /* id, SEL, ... */ ); 
```
上面已明确提示出，IMP一定包括id和SEL类型，也就是说方法内部会包含两个隐藏的参数self和_cmd，它们的类型就是对应的id和SEL
验证如下:

```Objective-C

// 获取selector
SEL selector = @selector(animalInstanceMethod);
// 获取animal中对应selector的方法实现
IMP imp = [animal methodForSelector: selector];
// 构造一个和IMP一样的函数指针，参数必须包括id和SEL两个参数,少则报错，多不影响
void (*func)(id, SEL) = (void *)imp;
// 下面故意将两个参数的值修改成其它
func(@"test", @selector(run));

- (void)animalInstanceMethod {
    NSLog(@"%@--%s", self, _cmd);
    /// 输出结果：test--run
}

```

总结一下：

- SEL: selector的简写, 方法选择器,实质存储的是方法的名称
- IMP: implement的简写, 方法实现,源码中它就是一个函数指针
- method_type: 描述方法的参数和返回值类型


- 分类的构造

利用clang生成的代码中可以发现 分类*Animal+Function2.m*的的定义，如下图展示：

![category.png](https://upload-images.jianshu.io/upload_images/1846524-713588a5e0d3131a.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

从上图可以发现
OC的底层生成了一个名为 _OBJC_$_CATEGORY_Animal_$_Function1类型为*struct _category_t*的变量，_OBJC_$_CATEGORY_Animal_$_Function1 变量的值已经被对应的数据进行填充。


