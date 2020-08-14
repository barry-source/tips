
# 一个NSObject对象占用多少空间

对于一个Object C对象，可以通过xcrun和clang命令来生成相应的底层代码，不过生成的代码不是最新的，具体的相关信息可以参考苹果官方源码。

如下一个**没有**任何变量的类，可以暂时通过 `xcrun -sdk iphoneos clang -arch arm64 -rewrite-objc main.m -o main64.cpp`（解释见附录）组合命令生成 底层cpp代码

```Objective-C
@interface OCObject : NSObject
@end

@implementation OCObject
@end
```

生成的源码中会出现一个`OCObject_IMPL`，这个就是 `OCObject`在底层的展现形式，可见其是一个结构体。结构体中只有一个`NSObject_IVARS`对象，其类型是`NSObject_IMPL`,它即是系统类`NSObject`的实现。

```Objective-C
struct OCObject_IMPL {
    struct NSObject_IMPL NSObject_IVARS;
};
```
跳转到`NSObject_IMPL`定义中，可以看到其它只有一个`isa`变量，其类型是`Class`

```Objective-C
struct NSObject_IMPL {
    Class isa;
};
```

跳转到`Class`定义中，可以看到它是一个类型别名，真实类型为`struct objc_class`

```Objective-C
typedef struct objc_class *Class;
```

跳转到`struct objc_class`定义中，内部只包含了一个自身类型的指针变量`isa`, 其变量已被标注 **deprecated**

```Objective-C
struct objc_class {
    Class _Nonnull isa __attribute__((deprecated));
} __attribute__((unavailable));

```

综上来说，相当于`OCObject_IMPL`直接拥有了一个`Class`类型的*isa*变量，因为结构体中的第一个变量的地址即是结构体的地址
(类比数组，数组首元素的地址既是数组的地址，结构体某种意义上也是一种数组--除去方法，只不过类型可以不一致而已)

```Objective-C
struct OCObject_IMPL {
    Class isa;
};
```
对于上面的总结来说，由于**isa**是一个指针类型，那么`OCObject_IMPL`占用的空间是8（64bit 平台）也即是`OCObject`占用的空间是8。同样的`NSObject`占用的空间是8

目前有两种测量NSObject对象占用空间的方法
- 通过runtime
```Objective-C
#import <objc/runtime.h>

class_getInstanceSize([obj class])

```

- 通过malloc
```Objective-C
#import <malloc/malloc.h>

malloc_size((__bridge const void *)(obj))

```
- 注意
苹果源码文档中已明确提出,不能用**sizeof**运算符，查看对象占用的大小
```Objective-C
Do not use sizeof(SomeClass). Use class_getInstanceSize([SomeClass class]) instead.
```
两种方式的结果分别是**8**和**16**


## class_getInstanceSize  在源码中的调用过程

objc-class.mm 中 `class_getInstanceSize -> alignedInstanceSize`
源码中对`alignedInstanceSize`的注释如下
```Objective-C
// Class's ivar size rounded up to a pointer-size boundary.
类的所有成员变量空间的大小，它以指针大小为边界，向上舍入（涉及到内存对齐）
```

## alloc  在源码中的调用过程
alloc 本质上是调用`allocWithZone`（NSObject.mm文件内）, 
`allocWithZone`内部又调用了`_objc_rootAllocWithZone`（objc-runtime-new.mm文件内）函数，
`_objc_rootAllocWithZone`内部调用了`_class_createInstanceFromZone`（objc-runtime-new.mm文件内）函数

`_class_createInstanceFromZone`函数内部有部分处理size的代码`size = cls->instanceSize(extraBytes);`（objc-runtime-new.mm文件内）

`instanceSize`的源码如下：
```Objective-C

size_t instanceSize(size_t extraBytes) const {
    if (fastpath(cache.hasFastInstanceSize(extraBytes))) {
        return cache.fastInstanceSize(extraBytes);
    }

    size_t size = alignedInstanceSize() + extraBytes;
    // CF requires all objects be at least 16 bytes.
    // CF对象至少需要16个字节
    if (size < 16) size = 16;
    return size;
}
```
# 结论：

- **系统分配了16个字节给NSObject对象（通过malloc_size函数获得）**

- **NSObject对象内部只使用了8个字节的空间（64bit环境下)，可以通过class_getInstanceSize函数获得**

# 附录：


Clang 是 c 、c++ 、object-c的编译器

### Clang常用命令：

查看编译源文件需要的几个不同的阶段
- clang -ccc-print-phases main.m

重新编译oc代码
- clang -arch arm64 -rewrite-objc main.m(要重写的文件) -o output.cpp(输出文件)


### xcrun常用命令
- xcrun -sdk iphoneos clang -arch arm64 -rewrite-objc main.m  -o  output.cpp  // 输出64位真机文件
- xcrun -sdk iphonesimulator13.5 clang -arch arm64 -rewrite-objc main.m  -o  output.cpp   // 输出64位模拟器文件
- xcodebuild -showsdks // 列出所有sdk
```python
iOS SDKs:
    iOS 13.5                          -sdk iphoneos13.5

iOS Simulator SDKs:
    Simulator - iOS 13.5              -sdk iphonesimulator13.5

macOS SDKs:
    DriverKit 19.0                    -sdk driverkit.macosx19.0
macOS 10.15                       -sdk macosx10.15

tvOS SDKs:
    tvOS 13.4                         -sdk appletvos13.4

tvOS Simulator SDKs:
    Simulator - tvOS 13.4             -sdk appletvsimulator13.4

watchOS SDKs:
    watchOS 6.2                       -sdk watchos6.2

watchOS Simulator SDKs:
    Simulator - watchOS 6.2           -sdk watchsimulator6.2

```

### 其它常用命令

-  查看配置文件（描述文件）信息，防止安装之后在/Library/MobileDevice/Provisioning Profiles路径中找不到安装的描述文件
```security cms -D -i tianxiao_adhoc.mobileprovision
```
- 查询静态库支持的格式
```lipo -info 文件名.a
```


[clang命令](https://www.jianshu.com/p/42cb026ce541)
