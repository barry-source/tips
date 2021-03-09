
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

#### 3.1 无参无返回值Block底层构造

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

int main(int argc, const char * argv[]) {
    /* @autoreleasepool */ { __AtAutoreleasePool __autoreleasepool; 
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

## 参考文档

[类对象和元类对象](http://www.sealiesoftware.com/blog/archive/2009/04/14/objc_explain_Classes_and_metaclasses.html)
