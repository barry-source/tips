
# 崩溃记录

## 常见
### 1、数组越界 NSRangeException：下标越界导致的异常。
### 2、UIKit Called on Non-Main Thread 非主线程更新UI
### 3、unrecognized selector 未实现的方法（解决方式利用respondsToSelector判断）
### 4、kvo未移除观察者崩溃-----iOS10以下会崩溃，iOS11以上不会崩溃
### 5、NSInvalidArgumentException：非法参数异常，传入非法参数导致异常，nil参数比较常见。
### 6、NSGenericException： foreach的循环当中修改元素导致的异常。


## 其它

### 1、类型转换崩溃
时间戳在32位机器上，使用Int类型崩溃，Int 会自动对应机器的位数。（ipad 4 ，32位机器）

### 2、多线程操作数组

下载时，多个线程同时执行，并记录下载的数据量(用一个数组保存)。线程很可能同时对数组进行append操作。在swift中append操作在合时的时候会进行扩容操作。这时就会产生类似`过度释放`的崩溃。比较隐蔽

### 3、音频代理在退出时未设置为nil崩溃，尤其在iOS 10

### 4、 多线程访问subscript崩溃

### 5、iPhone设置的是竖屏，但是在ipad上可能会出现横屏的现象，对present出的竖屏控制器dismiss时会崩溃

### 6、使用野指针崩溃

### 7、栈递归层次太深，导致栈溢出（案例，获取网络信息）

### 8、NSData 初始化
length 过大，数据异常，崩溃 或者size 为负数或者buffer为空
```python
    [NSData dataWithBytes:buffer length:size];
```

### 9：swift强制解包

### 10：

### 11：

### 12：

### 13：

