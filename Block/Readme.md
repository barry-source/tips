
# Block底层原理

###  1、Block简介

>  Block是封装了函数调用以及函数调用环境的OC对象。Block是C语言的扩充功能，简单来说就是带有自动变量的匿名函数

###  2、 Block类型
Block有三种类型，分别如下图所示：

![Block类型.jpg](https://upload-images.jianshu.io/upload_images/1846524-750537dfd6e06ffe.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

(MRC下)验证代码如下：
```python

void (^globalBlock)(void);

// 在MRC下测试
void blockType() {
    
    // 1、未捕获任何自动变量的block，是_NSConcreteGlobalBlock类型的
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

#### 3.1 未捕获任何变量Block底层构造

源码如下：
```python
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

```python
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
```python
void autoBlockImpl() {
    int autoVal = 1;
    void (^blk)(void) = ^{
        printf("%d\n", autoVal);
    };
    blk();
}
```

转换之后的代码不同点主要是Block的构造上：

```python
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

```python
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
```python
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

假如声明一个全局Block变量`Blk1`，同样在栈上声明一个Block变量`Blk2`，并进行了赋值操作，将`Blk2`赋值给`Blk1`, 正常在MRC下，`Blk2`所在的栈被销毁，那么`Blk2`也将被销毁，
这时调用`Blk1`将会出现异常，销毁示意图如下：

![栈上Block销毁示意图.jpg](https://upload-images.jianshu.io/upload_images/1846524-7f694e95f696ba03.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

但是在ARC下，`Blk1`是可以被调用的。 也就是说栈上的Block变量`Blk2`的生命周期被延长了。
那么是如何做到的呢。

其实就是将栈上的Block进行了Copy,全部放到栈上进行保存。

![延长栈上Block生命示意图.png](https://upload-images.jianshu.io/upload_images/1846524-c7c47e33d91a45b6.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

在`MRC`下，Block 中`__forwarding`指向的是它自己，就可以通知`autoVal->__forwarding->autoVal`存取捕获的变量。
在`ARC`下，栈上的`Bock`会被进行`copy`, `copy`之后会将栈上的`__forwarding`指向堆上的`Block`,这样无论在栈上或者堆上都可以正常的存取捕获的变量
所以`__forwarding`的作用就是无论在栈上或者堆上都可以正确访问`__block`变量

代码展示如下：
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

现在存在两个问题：
1、`Block`超出作用域可存在的原因
2、`__block`变量使用结构体成员变量`__forwarding`的原因

#### 3.2 访问全局变量或静态变量的Block底层构造



#### 3.2 捕获局部变量Block底层构造

底层构造和未捕获任何变量的Block大同小异，不同点如下所示：
```python
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
