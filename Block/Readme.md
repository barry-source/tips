
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

## 参考文档

[类对象和元类对象](http://www.sealiesoftware.com/blog/archive/2009/04/14/objc_explain_Classes_and_metaclasses.html)
