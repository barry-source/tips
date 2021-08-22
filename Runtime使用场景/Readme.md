
# Runtime使用场景：


1、由于+load方法是线程安全的，所以通常在+load方法内部做方法交换, 


坑1： 两次方法交换之后等于没有交换
load方法被子类重写之后调用了super，而方法交换并没有规定只执行一次，使用dispatch_onecetoken规避这种情况


坑2： 子类没有实现，父类实现了

因为imp找不到，父类调用会有问题

坑3： 交换根本没有实现的方法，父类只有声明，没有实现，子类也没有实现

出现死递归，自己调用自己

坑4： 找不到真正的方法归属

交换数组的objectAtIndex时不起作用 ，要找__NSArrayI的方法

https://juejin.cn/post/6844903812054908935

https://dhoerl.wordpress.com/2013/04/23/i-finally-figured-out-weakself-and-strongself/
 

2 方法签名：

方法签名是方法的形式定义，它提供了对该功能的高级描述 此签名格式要求方法参数、返回值、方法名称

此签名被视为模块的使用者和生产者之间的正式合同
