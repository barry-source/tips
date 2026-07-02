
# Block底层原理

###  1、Block简介

>  Block是封装了函数调用以及函数调用环境的OC对象。Block是C语言的扩充功能，简单来说就是带有自动变量的匿名函数

###  2、 Block类型
Block有三种类型，分别如下图所示：

![Block类型.jpg](https://upload-images.jianshu.io/upload_images/1846524-750537dfd6e06ffe.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

(MRC下)验证代码如下：
```objective-c

void (^globalBlock)(void);

// 在MRC下测试
void blockType() {
    
    // 1、未捕获任何自动变量的block，是_NSConcreteGlobalBlock类型的
    // 或者如果访问了外部static或者全局变量也是这种类
    globalBlock = ^{
    };
    
    int autoVal = 1;
    // 2、捕获自动变量的block，是_NSConcreteStackBlock类型的
    void (^stackBlock)(void) = ^{
        NSLog(@"%d", autoVal);
    };
    
    // 3、对栈上的Block进行copy操作之后会在堆上复制一份
    void (^mallocBlock)(void) = [stackBlock copy];
    
    NSLog(@"\n%@\n%@\n%@\n", globalBlock, stackBlock, mallocBlock);
    
    [mallocBlock release];
}

```

验证结果如下：

![Block类型验证.png](https://upload-images.jianshu.io/upload_images/1846524-aa02579d106e61fd.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

- ARC下会自动将栈上的Block复制到堆上，所以如需要验证，需要将Block类型设置为__weak

Block三种类型的存储区域如下图所示：

![Block存储区域.jpg](https://upload-images.jianshu.io/upload_images/1846524-f05c17653a1456c4.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

###  3、 Block实质

利用`Clang`命令可以将`OC`代码转换成底层的`c++`代码，大致看下底层的内部构造，当然也可以通过苹果官方提供的源码查看。

block的底层结构如下：
```c++
/* Revised new layout. */
struct Block_descriptor {
    unsigned long int reserved; //预留内存大小
    unsigned long int size; //块大小
    void (*copy)(void *dst, void *src); //指向拷贝函数的函数指针
    void (*dispose)(void *); //指向释放函数的函数指针
};

struct Block_layout {
    void *isa; //指向Class对象
    int flags; //状态标志位
    int reserved; //预留内存大小
    void (*invoke)(void *, ...); //指向块实现的函数指针
    struct Block_descriptor *descriptor;
    /* Imported variables. */
};

```

![image.png](https://upload-images.jianshu.io/upload_images/1846524-f5d2186205f01e9f.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
这个只是大致的一个描述，实际上用clang生成的底层代码稍有不同，invoke 对应 FuncPtr,  descriptor 并不在Block结构体内部等等。
#### 3.1 未捕获任何变量Block底层构造

源码如下：
```objective-c
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        void (^blk)(void) = ^{
            
        };
        
        blk();
    }
    return 0;
}
```

转换之后的代码如下：

```c++
// block的定义
struct __block_impl {
  void *isa;
  int Flags;
  int Reserved;
  void *FuncPtr;
};

// main函数中blk的底层构造
struct __main_block_impl_0 {
  struct __block_impl impl;         // block的实现
  struct __main_block_desc_0* Desc; // block的描述
  __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, int flags=0) { // 构造函数
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
};

// 外部的block执行代码被转换成了c语言的普通静态函数
static void __main_block_func_0(struct __main_block_impl_0 *__cself) {
    printf("Block\n");
}

static struct __main_block_desc_0 {
  size_t reserved;      // 保留字段
  size_t Block_size;    // Block结构体大小
} __main_block_desc_0_DATA = { 0, sizeof(struct __main_block_impl_0)};

int main(int argc, const char * argv[]) 
{ 
    /* @autoreleasepool */
    { 
        __AtAutoreleasePool __autoreleasepool; 
        
        void (*blk)(void) = ((void (*)())&__main_block_impl_0((void *)__main_block_func_0, &__main_block_desc_0_DATA));
        
        ((void (*)(__block_impl *))((__block_impl *)blk)->FuncPtr)((__block_impl *)blk);
        
        // 简化代码
        blk = __main_block_impl_0(
                                  __main_block_func_0,
                                  &__main_block_desc_0_DATA
                                  );
        blk->FuncPtr(blk);
    }
    return 0;
}
```

可以发现内部存在 一个 `isa`变量，这与对象的底层结构是一样的。所以Block也是一个对象。

#### 3.2 访问自动变量Block底层构造

源码如下：
```objective-c
void autoBlockImpl() {
    int autoVal = 1;
    void (^blk)(void) = ^{
        printf("%d\n", autoVal);
    };
    blk();
}
```

转换之后的代码不同点主要是Block的构造上：

```c++
struct __autoBlockImpl_block_impl_0 {
  struct __block_impl impl;
  struct __autoBlockImpl_block_desc_0* Desc;
  int autoVal;      // 这里将外部的自动变量进行了copy
  __autoBlockImpl_block_impl_0(void *fp, struct __autoBlockImpl_block_desc_0 *desc, int _autoVal, int flags=0) : autoVal(_autoVal) {
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
};


static void __autoBlockImpl_block_func_0(struct __autoBlockImpl_block_impl_0 *__cself) {
  int autoVal = __cself->autoVal; // bound by copy 这里访问的是底层内部的autoVal变量，外部变量的更改对此不会造成影响

  printf("%d\n", autoVal);
}
```

上述代码中Block内部没有对自动变量auto进行更改，如有需求，必须在类型前加上`__block`标识。但是这样一来，底层的构造就变成了另外一种方式。

示例存取`__block`自动变量的代码如下：

```objective-c
void blk() {
    __block int autoVal = 1;
    void (^blk)(void) = ^{
        autoVal += 1;
        printf("%d\n", autoVal);
    };
    blk();
}
```

转换后的代码如下所示：
```c++
// autoVal 被包裹成了__Block_byref_autoVal_0类型
struct __Block_byref_autoVal_0 {
  void *__isa;
  __Block_byref_autoVal_0 *__forwarding;  // 自身类型的变量
 int __flags;
 int __size;
 int autoVal;   // 初始化的时候会保存外部原始的数值
};

//__blockAutoBlock函数中blk的底层构造
struct __blk_block_impl_0 {
  struct __block_impl impl;
  struct __blk_block_desc_0* Desc;
  __Block_byref_autoVal_0 *autoVal; // by ref // 对比之前的类型int 这里的类型已经变成了__Block_byref_autoVal_0 *
  __blk_block_impl_0(void *fp, struct __blk_block_desc_0 *desc, __Block_byref_autoVal_0 *_autoVal, int flags=0) : autoVal(_autoVal->__forwarding) {
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
};

// 外部的block执行代码被转换成了c语言的普通静态函数
static void __blk_block_func_0(struct __blk_block_impl_0 *__cself) {
  __Block_byref_autoVal_0 *autoVal = __cself->autoVal; // bound by ref

  (autoVal->__forwarding->autoVal) += 1;
  printf("%d\n", (autoVal->__forwarding->autoVal));
}

// 对包裹的成对象的autoVal进行强引用的操作
static void __blk_block_copy_0(struct __blk_block_impl_0*dst, struct __blk_block_impl_0*src) 
{
    _Block_object_assign((void*)&dst->autoVal, (void*)src->autoVal, 8/*BLOCK_FIELD_IS_BYREF*/);
}

// 对包裹的成对象的autoVal进行释放的操作
static void __blk_block_dispose_0(struct __blk_block_impl_0*src) 
{
    _Block_object_dispose((void*)src->autoVal, 8/*BLOCK_FIELD_IS_BYREF*/);
}

static struct __blk_block_desc_0 {
  size_t reserved;
  size_t Block_size;
  // 相比只读取自动变量的block这里多了copy和dispose函数
  void (*copy)(struct __blk_block_impl_0*, struct __blk_block_impl_0*);
  void (*dispose)(struct __blk_block_impl_0*);
} __blk_block_desc_0_DATA = { 0, sizeof(struct __blk_block_impl_0), __blk_block_copy_0, __blk_block_dispose_0};

void blk() {
    __attribute__((__blocks__(byref))) __Block_byref_autoVal_0 autoVal = {(void*)0,(__Block_byref_autoVal_0 *)&autoVal, 0, sizeof(__Block_byref_autoVal_0), 1};
    void (*blk)(void) = ((void (*)())&__blk_block_impl_0((void *)__blk_block_func_0, &__blk_block_desc_0_DATA, (__Block_byref_autoVal_0 *)&autoVal, 570425344));
    
    // 简化代码
    __Block_byref_autoVal_0 autoVal = {
         0,
         (__Block_byref_autoVal_0 *)&autoVal,
         0,
         sizeof(__Block_byref_autoVal_0),
         1
         };
    void (*blk)(void) = __blk_block_impl_0(__blk_block_func_0,
                                           &__blk_block_desc_0_DATA,
                                           (__Block_byref_autoVal_0 *)&autoVal,
                                           570425344
                                           );
    blk->FuncPtr(blk);
}
```

对比下只读取自动变量的block不同点：

![__block.jpg](https://upload-images.jianshu.io/upload_images/1846524-41af36cbfa57bb7b.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


可以看出标识`__block`的变量底层结构体中包裹了一个类型为`__Block_byref_autoVal_0`结构体变量，这个结构体中
1、`int autoVal`的初始值为` 1`
2、`__Block_byref_autoVal_0 *__forwarding`的值指向了自身，所以可以通过 `autoVal->__forwarding->autoVal`来存取内部`int autoVal`的值。


```
void (^Blk1)(void);

void blk() {
    __block int autoVal = 1;
    void (^Blk2)(void) = ^{
        autoVal += 1;
    };
    Blk1 = Blk2;
}

```

假如声明一个全局Block变量`Blk1`，同样在栈上声明一个Block变量`Blk2`，并进行了赋值操作，将`Blk2`赋值给`Blk1`, 正常在MRC下，`Blk2`所在的栈被销毁，那么`Blk2`也将被销毁，
这时调用`Blk1`将会出现异常，销毁示意图如下：

![栈上Block销毁示意图.jpg](https://upload-images.jianshu.io/upload_images/1846524-7f694e95f696ba03.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

但是在ARC下，`Blk1`是可以被调用的。 也就是说栈上的Block变量`Blk2`的生命周期被延长了。
那么是如何做到的呢。

其实就是将栈上的Block进行了Copy,全部放到堆上进行保存。

![延长栈上Block生命示意图.png](https://upload-images.jianshu.io/upload_images/1846524-c7c47e33d91a45b6.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

在`MRC`下，Block 中`__forwarding`指向的是它自己，就可以通知`autoVal->__forwarding->autoVal`存取捕获的变量。
在`ARC`下，栈上的`Block`会被进行`copy`, `copy`之后会将栈上的`__forwarding`指向堆上的`Block`,这样无论在栈上或者堆上都可以正常的存取捕获的变量
所以`__forwarding`的作用就是无论在栈上或者堆上都可以正确访问`__block`变量


#### 3.2 访问全局变量或静态变量的Block底层构造


#### 3.3 捕获局部变量Block底层构造

底层构造和未捕获任何变量的Block大同小异，不同点如下所示：
```c++
struct __basicAutoBlockImpl_block_impl_0 {
  struct __block_impl impl;
  struct __basicAutoBlockImpl_block_desc_0* Desc;
  int autoVal;      // 这里对自动变量进行了复制，外部对autoVal的修改不影响结构体内部的值
  __basicAutoBlockImpl_block_impl_0(void *fp, struct __basicAutoBlockImpl_block_desc_0 *desc, int _autoVal, int flags=0) : autoVal(_autoVal) {
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
};

static void __basicAutoBlockImpl_block_func_0(struct __basicAutoBlockImpl_block_impl_0 *__cself) {
  int autoVal = __cself->autoVal; // bound by copy 这里取出结体中autoVal的值
  printf("%d\n", autoVal);
}
```

## 参考文档

[类对象和元类对象](http://www.sealiesoftware.com/blog/archive/2009/04/14/objc_explain_Classes_and_metaclasses.html)

---

## 四、Block 的变量捕获机制

### 4.1 捕获的变量类型

| 变量类型 | Block 内部能否修改 | 捕获方式 | 说明 |
|---------|-------------------|---------|------|
| **局部变量（基本类型）** | ❌ 不能 | **值拷贝** | 捕获的是值，外部修改不影响 |
| **局部变量（对象类型）** | ❌ 不能 | **强引用（retain）** | 捕获的是对象指针，ARC 下自动 retain |
| **静态变量** | ✅ 能 | **指针拷贝** | 捕获的是指针，可以直接修改 |
| **全局变量** | ✅ 能 | **直接访问** | 不捕获，直接访问全局区 |
| **\_\_block 变量** | ✅ 能 | **封装为对象** | 包装成 `__Block_byref_xxx` 结构体 |

```objc
// 验证代码
int globalVal = 10;           // 全局变量
static int staticVal = 20;    // 静态变量

void testCapture() {
    int localVal = 30;                     // 局部变量（基本类型）
    NSMutableArray *array = @[].mutableCopy; // 局部变量（对象类型）
    __block int blockVal = 40;              // __block 变量

    void (^block)(void) = ^{
        // globalVal++;    // ✅ 可以直接修改（全局变量）
        // staticVal++;    // ✅ 可以直接修改（静态变量）
        // localVal++;     // ❌ 编译错误，不能修改
        // array = @[].mutableCopy; // ❌ 不能重新赋值
        [array addObject:@"new"]; // ✅ 可以修改对象内容
        blockVal++;          // ✅ 可以修改（__block 变量）

        NSLog(@"%d %d %d %d", globalVal, staticVal, localVal, blockVal);
    };

    localVal = 31;  // block 内部不会感知这个修改（捕获的是值拷贝）
    blockVal = 41;  // block 内部能感知（__block 变量是引用）
    block();
}
```

### 4.2 对象类型变量的捕获细节

```objc
// 当 Block 捕获了 OC 对象时，ARC 下会自动添加 retain/release

typedef void (^Block)(void);

Block globalBlock;

void testObjectCapture() {
    NSObject *obj = [[NSObject alloc] init];   // retainCount = 1
    NSLog(@"%ld", CFGetRetainCount((__bridge CFTypeRef)obj)); // 1

    globalBlock = ^{
        NSLog(@"%@", obj);  // Block 强引用 obj → retainCount +1
    };

    NSLog(@"%ld", CFGetRetainCount((__bridge CFTypeRef)obj)); // 2（Block retained）

    globalBlock = nil;  // Block 释放 → obj release → retainCount -1
    NSLog(@"%ld", CFGetRetainCount((__bridge CFTypeRef)obj)); // 1
}

// 底层 C++ 结构（clang 转换后）
// descriptor 中增加了 copy/dispose 函数
struct __testObjectCapture_block_desc_0 {
    size_t reserved;
    size_t Block_size;
    void (*copy)(struct __testObjectCapture_block_impl_0*, struct __testObjectCapture_block_impl_0*);
    void (*dispose)(struct __testObjectCapture_block_impl_0*);
};

// copy 时：Block 拷贝到堆上 → retain 捕获的对象
static void __testObjectCapture_block_copy_0(struct __testObjectCapture_block_impl_0*dst, struct __testObjectCapture_block_impl_0*src) {
    _Block_object_assign((void*)&dst->obj, (void*)src->obj, 3/*BLOCK_FIELD_IS_OBJECT*/);
}

// dispose 时：Block 释放 → release 捕获的对象
static void __testObjectCapture_block_dispose_0(struct __testObjectCapture_block_impl_0*src) {
    _Block_object_dispose((void*)src->obj, 3/*BLOCK_FIELD_IS_OBJECT*/);
}
```

---

## 五、Block 的 copy 操作

### 5.1 三种 Block 的存放位置

| Block 类型 | 初始位置 | copy 后位置 | isa 指向 |
|-----------|---------|------------|---------|
| `_NSConcreteGlobalBlock` | 全局区（数据段） | 全局区（copy 无效果） | `_NSConcreteGlobalBlock` |
| `_NSConcreteStackBlock` | 栈区 | 堆区 | `_NSConcreteMallocBlock` |
| `_NSConcreteMallocBlock` | 堆区 | 堆区（引用计数 +1） | `_NSConcreteMallocBlock` |

### 5.2 ARC 下自动 copy 的时机

ARC 下，编译器会在以下情况**自动**将栈上的 Block copy 到堆上：

| 场景 | 示例 | 结果 |
|------|------|------|
| **Block 赋值给强引用** | `self.block = ^{ }` | 自动 copy 到堆 |
| **Block 作为返回值** | `return ^{ }` | 自动 copy 到堆 |
| **Block 作为方法参数** | `dispatch_async(queue, block)` | 自动 copy（GCD API 内部） |
| **Cocoa 方法名包含 usingBlock** | `array enumerateObjectsUsingBlock:` | 自动 copy |
| **Block 赋值给 __strong 指针** | `__strong typeof(block) strongBlock = block` | 自动 copy |

```objc
// ARC 下自动 copy 验证
void testAutoCopy() {
    int val = 10;

    // ARC 下，block 实际上是 __strong 类型 → 自动 copy 到堆
    void (^block)(void) = ^{
        NSLog(@"%d", val);
    };

    // block 的类型是 _NSConcreteMallocBlock（堆上），不是 StackBlock
    NSLog(@"%@", [block class]);  // __NSMallocBlock__
}

// ARC 下验证栈 Block 的方式需要加 __weak
void testStackBlock() {
    int val = 10;
    void (^__weak weakBlock)(void) = ^{
        NSLog(@"%d", val);
    };
    NSLog(@"%@", [weakBlock class]);  // __NSStackBlock__（栈上）
}

// MRC 下不加 copy 就是栈 Block
// ARC 下不加 __weak 默认是堆 Block
```

### 5.3 copy 过程详解

```
Block copy 的过程（从栈 copy 到堆）：

① 在堆上分配内存（大小 = Block 结构体大小）
② 将栈上 Block 的数据拷贝到堆上（memmove）
③ 修改堆上 Block 的 isa 为 _NSConcreteMallocBlock
④ 执行 descriptor 中的 copy 函数：
   ├── __block 变量：_Block_object_assign(..., BLOCK_FIELD_IS_BYREF)
   │   → 将 __block 变量也从栈 copy 到堆
   │   → 更新 __forwarding 指针指向堆上的 __block 变量
   │
   └── 对象类型变量：_Block_object_assign(..., BLOCK_FIELD_IS_OBJECT)
       → retain 捕获的对象

⑤ 返回堆上 Block 的地址
```

---

## 六、__block 变量详解

### 6.1 __forwarding 指针的作用

`__forwarding` 是指向 `__Block_byref_xxx` 结构体自身的指针。

```
栈上 Block（MRC）：
  autoVal (栈) → __forwarding → 指向自己（栈）
                 autoVal = 1

堆上 Block（ARC copy 后）：
  autoVal (栈) → __forwarding → 指向堆上的 autoVal（更新过）
  autoVal (堆) → __forwarding → 指向自己（堆）
                 autoVal = 1
```

**作用**：无论在栈上还是堆上访问 `__block` 变量，都能通过 `autoVal->__forwarding->autoVal` 访问到**堆上的实际值**。

```c
// 修改 __block 变量的底层代码
(autoVal->__forwarding->autoVal) += 1;

// 如果 Block 在栈上（MRC）：__forwarding → 栈上 autoVal
// 如果 Block 在堆上（ARC）：__forwarding → 堆上 autoVal
// 两者都能正确修改
```

### 6.2 __block 变量的内存管理

```objc
// __block 变量的引用计数管理
// 当 Block 从栈 copy 到堆时：
//   ① 栈上的 __block 变量也 copy 到堆
//   ② 堆上的 __block 变量引用计数设为 1
//   ③ 栈上的 __forwarding 指向堆上的 __block 变量

// 当多个 Block 都捕获同一个 __block 变量时：
//   第一个 Block copy 时：__block 变量从栈 → 堆（retainCount = 1）
//   第二个 Block copy 时：__block 变量引用计数 +1（retainCount = 2）
//   所有 Block 都释放后：__block 变量引用计数为 0 → dealloc
```

### 6.3 __block 在 ARC 和 MRC 下的区别

```objc
// MRC 下：
__block NSObject *obj = [[NSObject alloc] init];
// __block 不会 retain 对象，不会造成循环引用
// 所以 MRC 下可以用 __block 打破循环引用

// ARC 下：
__block NSObject *obj = [[NSObject alloc] init];
// __block 会强引用对象（同 __strong）
// 所以 ARC 下用 __weak 而不是 __block 打破循环引用

// ARC 下打破循环引用的正确方式：
__weak typeof(self) weakSelf = self;
self.block = ^{
    NSLog(@"%@", weakSelf);
};
```

---

## 七、Block 的循环引用分析

### 7.1 循环引用场景

```objc
// ❌ 循环引用
self.block = ^{
    [self doSomething];  // self → block → self
};
// 关系链：self 持有 block，block 捕获了 self（强引用）

// ✅ 解决方案
__weak typeof(self) weakSelf = self;
self.block = ^{
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (!strongSelf) return;
    [strongSelf doSomething];
};
```

### 7.2 循环引用检测方法

| 方法 | 操作 | 效果 |
|------|------|------|
| **Xcode Memory Graph** | Debug → Memory Graph | 可视化查看引用链 |
| **dealloc 日志** | `NSLog(@"dealloc")` | 确认对象是否释放 |
| **Instruments Leaks** | Product → Profile → Leaks | 实时检测泄漏 |

```objc
// 验证是否释放
- (void)dealloc {
    NSLog(@"✅ %@ dealloc", NSStringFromClass([self class]));
}
```

---

## 八、Block 底层结构完整图解

```
Block 内存布局（捕获 __block 变量的堆 Block）：
┌─────────────────────────────────────┐
│  __NSMallocBlock_impl（isa 结构体）   │
│  ┌───────────────────────────────┐  │
│  │ isa = _NSConcreteMallocBlock  │  │  ← 对象类型标识
│  │ Flags                        │  │  ← 状态标志（BLOCK_HAS_COPY_DISPOSE等）
│  │ Reserved                     │  │  ← 保留
│  │ FuncPtr                      │  │  ← 指向 __block_func_0 函数指针
│  │ Descriptor → ─────────────── │  │  ← 指向描述信息
│  │ autoVal (__block var) → ──── │  │  ← 捕获的 __block 变量指针
│  └───────────────────────────────┘  │
├─────────────────────────────────────┤
│  Block Descriptor                    │
│  ┌───────────────────────────────┐  │
│  │ reserved                      │  │
│  │ size（Block 结构体大小）        │  │
│  │ copy（_Block_object_assign）   │  │  ← 拷贝时调用
│  │ dispose（_Block_object_dispose）│  │  ← 释放时调用
│  └───────────────────────────────┘  │
│                      ▲              │
├──────────────────────┼──────────────┤
│  __Block_byref_autoVal               │
│  ┌───────────────────────────────┐  │
│  │ __isa (0)                     │  │
│  │ __forwarding → 指向自己        │  │  ← 保证栈/堆都能正确访问
│  │ __flags                       │  │
│  │ __size                        │  │
│  │ autoVal（实际值）              │  │  ← 真正存储的变量值
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

---

## 九、Block 面试题

### 1. Block 的本质是什么？

Block 是封装了**函数调用**和**函数调用环境**的 **OC 对象**。底层是 `__block_impl` 结构体，包含 isa 指针，所以 Block 也是一个对象。

### 2. Block 有几种类型？分别在什么位置？

三种：`_NSConcreteGlobalBlock`（全局区）、`_NSConcreteStackBlock`（栈区）、`_NSConcreteMallocBlock`（堆区）。未捕获变量的 Block 在全局区，捕获变量的 Block 初始在栈上，copy 后到堆上。

### 3. 为什么 Block 不能修改普通的局部变量？

因为 Block 捕获局部变量是**值拷贝**（pass-by-copy），Block 内部的变量是外部变量的副本，修改副本没有意义。如果想修改需要用 `__block` 修饰，底层会包装成 `__Block_byref_xxx` 结构体（引用传递）。

### 4. __block 的底层原理是什么？

`__block` 将变量包装成 `__Block_byref_xxx` 结构体对象。结构体中有 `__forwarding` 指针，保证无论在栈上还是堆上都能正确访问实际值。Block copy 到堆时，`__block` 变量也会被 copy 到堆，`__forwarding` 指向堆上的变量。

### 5. ARC 下 Block 什么时候会被自动 copy？

赋值给强引用、作为返回值、作为方法参数（usingBlock）、GCD API 等场景下，ARC 会自动将栈上的 Block copy 到堆上。

### 6. Block 中 __weak 和 __block 的区别？

- `__weak`：不 retain 对象，用于**打破循环引用**
- `__block`：将变量包装为对象，用于在 Block 内部**修改变量的值**
- ARC 下 `__block` 会 retain 对象（同 `__strong`），`__weak` 不会

### 7. Block 捕获对象类型的变量时，内存如何管理？

Block 的 descriptor 中会生成 copy/dispose 函数。copy 时 `_Block_object_assign` 会 retain 对象，dispose 时 `_Block_object_dispose` 会 release 对象。保证了 Block 持有对象期间对象不会被释放。

### 8. __forwarding 指针的作用是什么？

保证无论在栈上还是堆上，通过 `__forwarding` 都能访问到**堆上的实际值**。Block 从栈 copy 到堆后，栈上 `__forwarding` 指向堆上结构体，堆上 `__forwarding` 指向自己。

### 9. MRC 和 ARC 下 Block 的区别？

| 区别 | MRC | ARC |
|------|-----|-----|
| 栈 Block 自动 copy | ❌ 不会 | ✅ 会自动 copy |
| `__block` 是否 retain 对象 | ❌ 不 retain | ✅ 会 retain（同 strong） |
| 打破循环引用 | `__block` | `__weak` |
| Block 属性修饰 | `copy` | `strong` / `copy`（效果一样） |
