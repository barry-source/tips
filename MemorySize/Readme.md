
# iOS内存分配原则

## 对齐原则：

```python 
1、数据成员对齐规则：结构体的首个数据成员放在偏移量为0的地方，后序的数据成员偏移量为 #pragma pack(n) 指定的数据 n 和数据成员占用字节大小的最小值的整数倍，少则补齐.
2、结构体中包含结构体，该结构体成“自身数据”类型占用的大小为结构体中成员类型占用最大字节数。
3、结构体的整体对齐规则：结构体在按照规则 1 对齐之后,结构体本身也要对齐。最终大小为 #pragma pack(n) 指定的数据 n 和结构体中成员占用的最大字节数中最小值的整数倍，少则补齐.
```


## 案例1：#pragma pack(1) 一字节对齐
```Objective-C
#pragma pack(1)
struct CustomType {
    //1、数据成员对齐规则
    char a;     // 占用空间大小1 = 1, 偏移量为 1 的倍数, 偏移量为 0, 存放空间位置 [0]
    short b;    // 占用空间大小2 > 1, 偏移量为 1 的倍数, 偏移量为 1, 存放空间位置 [1, 2]
    char c;     // 占用空间大小1 = 1, 偏移量为 1 的倍数, 偏移量为 3, 存放空间位置 [3]
    int d;      // 占用空间大小4 > 1, 偏移量为 1 的倍数, 偏移量为 4, 存放空间位置 [4, 7]
    char e;     // 占用空间大小1 = 1, 偏移量为 1 的倍数, 偏移量为 8, 存放空间位置 [8]
    // 数据成员总共占用空间为 [0, 8] 共9个字节
};
//3、结构体的整体对齐规则: min(1, max(short, char, int)) = 1, 9 是 1 的整数倍，所以结构体最终占用空间为9个字节。
#pragma pack()
```

### 对齐示意图：

![pack1.jpg](https://upload-images.jianshu.io/upload_images/1846524-98586fbbf290d7a6.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


## 案例2：#pragma pack(2) 二字节对齐
```Objective-C
## 案例1：#pragma pack(1) 一字节对齐
```Objective-C
#pragma pack(2)
struct CustomType {
    //1、数据成员对齐规则
    char a;     // 占用空间大小1 < 2, 偏移量为 1 的倍数, 偏移量为 0,  存放空间位置 [0]
    short b;    // 占用空间大小2 = 2, 偏移量为 2 的倍数, 偏移量为 2,  存放空间位置 [2, 3]
    char c;     // 占用空间大小1 < 2, 偏移量为 1 的倍数, 偏移量为 4， 存放空间位置 [4]
    int d;      // 占用空间大小4 > 2, 偏移量为 2 的倍数, 偏移量为 6， 存放空间位置 [6, 9]
    char e;     // 占用空间大小1 < 2, 偏移量为 1 的倍数, 偏移量为 10，存放空间位置 [10]
    // 数据成员总共占用空间为 [0, 10] 共11个字节
};
//3、结构体的整体对齐规则: min(2, max(short, char, int)) = 2, 11 不是 2 的整数倍，空间大小变为 12，所以结构体最终占用空间为 12 个字节。
#pragma pack()
```

### 对齐示意图：

![pace 2.jpg](https://upload-images.jianshu.io/upload_images/1846524-3bab91a20138722c.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

-  **X**为补齐部分

## 案例3：#pragma pack(4) 四字节对齐
```Objective-C
## 案例1：#pragma pack(1) 一字节对齐
```Objective-C
#pragma pack(4)
struct CustomType {
    //1、数据成员对齐规则
    char a;     // 占用空间大小1 < 4, 偏移量为 1 的倍数, 偏移量为 0,  存放空间位置 [0]
    short b;    // 占用空间大小2 < 4, 偏移量为 2 的倍数, 偏移量为 2,  存放空间位置 [2, 3]
    char c;     // 占用空间大小1 < 4, 偏移量为 1 的倍数, 偏移量为 4,  存放空间位置 [4]
    int d;      // 占用空间大小4 = 4, 偏移量为 4 的倍数, 偏移量为 8,  存放空间位置 [8, 11]
    char e;     // 占用空间大小1 < 4, 偏移量为 1 的倍数, 偏移量为 12, 存放空间位置 [12]
    // 数据成员总共占用空间为 [0, 12] 共13个字节
};
//3、结构体的整体对齐规则: min(4, max(short, char, int)) = 4, 13 不是 4 的整数倍，空间大小变为 16，所以结构体最终占用空间为 16 个字节。
#pragma pack()
```

### 对齐示意图：

![pack 4.jpg](https://upload-images.jianshu.io/upload_images/1846524-4ee86c0e8837a4db.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


-  **X**为补齐部分


## 案例4：#pragma pack(8) 八字节对齐
```Objective-C
#pragma pack(8)
struct CustomType {
    //1、数据成员对齐规则
    char a;     // 占用空间大小1 < 8, 偏移量为 1 的倍数, 偏移量为 0,  存放空间位置 [0]
    short b;    // 占用空间大小2 < 8, 偏移量为 2 的倍数, 偏移量为 2,  存放空间位置 [2, 3]
    char c;     // 占用空间大小1 < 8, 偏移量为 1 的倍数, 偏移量为 4,  存放空间位置 [4]
    int d;      // 占用空间大小4 < 8, 偏移量为 4 的倍数, 偏移量为 8,  存放空间位置 [8, 11]
    char e;     // 占用空间大小1 < 8, 偏移量为 1 的倍数, 偏移量为 12, 存放空间位置 [12]
    // 数据成员总共占用空间为 [0, 12] 共13个字节
};
//3、结构体的整体对齐规则: min(8, max(short, char, int)) = 4, 13 不是 4 的整数倍，空间大小变为 16，所以结构体最终占用空间为 16 个字节。
#pragma pack()
```

### 对齐示意图：

![pack 4.jpg](https://upload-images.jianshu.io/upload_images/1846524-4ee86c0e8837a4db.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


-  **X**为补齐部分


## 案例5：#pragma pack(4) 结构体嵌套
```Objective-C
#pragma pack(4)
struct CustomType {
    //1、数据成员对齐规则
    char a;                 // 占用空间大小1 < 4, 偏移量为 1 的倍数, 偏移量为 0,  存放空间位置 [0]
    short b;                // 占用空间大小2 < 4, 偏移量为 2 的倍数, 偏移量为 2,  存放空间位置 [2, 3]
    struct InnerCustomType {
        //1、数据成员对齐规则
        int a1;             // 占用空间大小4 = 4, 偏移量为 4 的倍数, 偏移量为 4,   存放空间位置 [4, 7]
        char b1;            // 占用空间大小1 < 4, 偏移量为 1 的倍数, 偏移量为 8,   存放空间位置 [8]
        short c1;           // 占用空间大小2 < 4, 偏移量为 2 的倍数, 偏移量为 10,  存放空间位置 [10, 11]
        char d1;            // 占用空间大小1 < 4, 偏移量为 1 的倍数, 偏移量为 12,  存放空间位置 [12]
        // InnerCustomType 数据成员总共占用空间为 [4, 12] 共9个字节
        //3、结构体的整体对齐规则: min(4, max(short, char, int)) = 4, 9 不是 4 的整数倍，InnerCustomType空间大小变为 12，所以InnerCustomType结构体最终占用空间为 12 个字节, 范围[4, 15]
    } c;
    int d;                  // 占用空间大小4 = 4, 偏移量为 4 的倍数, 偏移量为 16,  存放空间位置 [16, 19]
    char e;                 // 占用空间大小1 < 4, 偏移量为 1 的倍数, 偏移量为 20,  存放空间位置 [20]
    // CustomType结构体数据成员总共占用空间为 [0, 20] 共21个字节
};
//3、结构体的整体对齐规则: min(4 max(short, char, int, InnerCustomType)) = 4, 21 不是 4 的整数倍，空间大小变为 24，所以结构体最终占用空间为 24 个字节。
#pragma pack()
```

### 对齐示意图：

![结构体嵌套.jpg](https://upload-images.jianshu.io/upload_images/1846524-cd49f8e573058583.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

- **X**为补齐部分

## 案例6：#pragma pack(4) 综合展示
```Objective-C
struct CustomType {
    //1、数据成员对齐规则
    char a[2];              // 占用空间大小1 < 4, 偏移量为 1 的倍数, 偏移量为 0,  存放空间位置 [0, 1]
    short b;                // 占用空间大小2 < 4, 偏移量为 2 的倍数, 偏移量为 2,  存放空间位置 [2, 3]
    struct InnerCustomType {
        //1、数据成员对齐规则
        int a1;             // 占用空间大小4 = 4, 偏移量为 4 的倍数, 偏移量为 4,   存放空间位置 [4, 7]
        char b1;            // 占用空间大小1 < 4, 偏移量为 1 的倍数, 偏移量为 8,   存放空间位置 [8]
        long c1;            // 占用空间大小8 > 4, 偏移量为 4 的倍数, 偏移量为 12,  存放空间位置 [12, 19]
        // InnerCustomType 数据成员总共占用空间为 [4, 19] 共16个字节
        //3、结构体的整体对齐规则: min(4, max(long, char, int)) = 4, 16 是 4 的整数倍，空间大小变为 16，所以InnerCustomType结构体最终占用空间为 16 个字节, 范围[4, 19]
    } c;
    int d;                  // 占用空间大小4 = 4, 偏移量为 4 的倍数, 偏移量为 20,  存放空间位置 [20, 23]
    // CustomType结构体数据成员总共占用空间为 [0, 23] 共24个字节
};
//3、结构体的整体对齐规则: min(4 max(short, char, int, InnerCustomType)) = 4, 24 是 4 的整数倍，空间大小变为 24，所以结构体最终占用空间为 24 个字节。
#pragma pack()
```

### 对齐示意图：

![综合展示.jpg](https://upload-images.jianshu.io/upload_images/1846524-53eed27194d38399.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


-  **X**为补齐部分

## 取消编译器的自动对齐

- 一是通过案例1中的方式 `#pragma pack(1)`和`#pragma pack( )`
- 二是通过GNU C 中的`__attribute__`机制, 具体来说就是使用 `__attribute__((packed))`,示例如下：
```Objective-C
// 即使设置了#pragma pack(4)，由于结构体中使用了__attribute__((packed)) 属性，依然取消了设置的对齐方式
#pragma pack(4)
struct CustomType {
    char a;     // 占用1个字节
    short b;    // 占用2字节
    char c;     // 占用1个字节
    int d;      // 占用4个字节
    char e;     // 占用1个字节
} __attribute__((packed));
// __attribute__((packed)) 状态下总共占用 9 个字节
#pragma pack()
```

#### - 上述代码中设置了#pragma pack(4)，但是由于结构体中使用了__attribute__((packed)) 属性，依然取消了设置的对齐方式
#### - __attribute__ ((aligned (1))) 方式，目前在xcode中不起使用,参考![链接](https://stackoverflow.com/questions/10371296/pragma-pack1-nor-attribute-aligned-1-works)

## iOS平台对齐

iOS平台的对齐系数为8，可以通过下述论证。


由[一个NSObject占用多少空间](https://github.com/barry-source/tips/tree/master/NSObjectSize)文章可知，NSObject对象底层的表现形式为c++中的结构体。
利用`xcrun -sdk iphoneos clang -arch arm64 -rewrite-objc -fpack-struct=8 TestObject.m -o testObject.cpp`命令可以生成相应的c++代码
由底层代码可以构造以下结构：

##### 正常形式
```
// NSOject 的展现形式
struct NSObject_IMPL {
    Class isa;
};
// 继承NSOject的TestObject展现形式
struct TestObject_IMPL {
    struct NSObject_IMPL NSObject_IVARS; // 这里可以直接用 Class isa;替换
    int p1;
    int p2;
    char p3;
};
struct TestObject_IMPL s;
NSLog(@"%zd", sizeof(s));
```

##### #pragma pack(4)

```
// NSOject 的展现形式
struct NSObject_IMPL {
    Class isa;
};
#pragma pack(4)
// 继承NSOject的TestObject展现形式
struct TestObject_IMPL {
struct NSObject_IMPL NSObject_IVARS; // 这里可以直接用 Class isa;替换
    int p1;
    int p2;
    char p3;
};
#pragma pack()
struct TestObject_IMPL s;
NSLog(@"%zd", sizeof(s));
```
##### #pragma pack(8)

```
// NSOject 的展现形式
struct NSObject_IMPL {
    Class isa;
};
#pragma pack(8)
// 继承NSOject的TestObject展现形式
struct TestObject_IMPL {
struct NSObject_IMPL NSObject_IVARS; // 这里可以直接用 Class isa;替换
    int p1;
    int p2;
    char p3;
};
#pragma pack()
struct TestObject_IMPL s;
NSLog(@"%zd", sizeof(s));
```
三种方式的打印结果分别是 `24` `20` `24`,由此得出iOS平台的对齐系数为 `8`

- 补充 `class_getInstanceSize`返回的是对齐之后的空间大小。
`class_getInstanceSize`实现如下：
```
size_t class_getInstanceSize(Class cls)
{
    if (!cls) return 0;
    return cls->alignedInstanceSize(); //返回的是对齐之后的大小
}
```

`alignedInstanceSize`实现如下：
```
// Class's ivar size rounded up to a pointer-size boundary.
uint32_t alignedInstanceSize() const {
    return word_align(unalignedInstanceSize()); // 将未对齐的空间进行对齐
}
```
`word_align`是一个宏定义，其定义如下：

```
#ifdef __LP64__
#   define WORD_SHIFT 3UL
#   define WORD_MASK 7UL
#   define WORD_BITS 64
#else
#   define WORD_SHIFT 2UL
#   define WORD_MASK 3UL
#   define WORD_BITS 32
#endif

static inline size_t word_align(size_t x) {
    return (x + WORD_MASK) & ~WORD_MASK;
}
```
由于当前Mac 系统为 10.15.6，为64位系统，故 `#ifdef __LP64__`成立，**WORD_MASK = 7**，`word_align`的计算结果为  (x + 7) & 0xFFFFFFF8, 对于一个空的NSObject来说，至少包含一个**isa**指针，所以x的大小至少是8，所以 (x + 7) & 0xFFFFFFF8的结果至少是8

- LP64: 在64位机器上，如果int是32位，long是64位，pointer也是64位，那么该机器就是LP64的，其中的L表示Long，P表示Pointer，64表示Long和Pointer都是64位的.(Unix 和 Unix 类的系统 )

