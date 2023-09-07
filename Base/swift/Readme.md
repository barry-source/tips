# 1.Swift 语言介绍
1. Swift是一门安全、快速、可交互的编程语言。
2. Swift是一种工业级的编程语言，同时与脚本语言一样富有表现力和趣味性。
3. Swift采用类型推断和模式匹配，使代码易写易读 
4. Swift代码经过编译和优化，可充分利用现代硬件
5. Swift通过采用现代编程模式来定义大量常见的编程错误，其中包括
    * 变量在使用之前必须初始化
    * 数组切片检查越界错误
    * 整型检查溢出错误
    * Optional确保nil值被显式处理
    * 自动内存管理
    * 可控可恢复的错误处理
6. Swift支持面向对象编程，函数式编程和面向协议编程

# 2.Swift 和 OC 区别
Swift支持面向对象编程，函数式编程和面向协议编程，OC 以面向对象编程为主
Swift支持动态库，oc不支持
Swift是类型安全的静态语言，而OC是动态类型语言，类型的确定推迟到运行时。类型在编译时是不确定的。
Swift侧重的是值类型，而OC侧重的是引用类型
Swift函数是一等类型，而OC函数是次等类型
Swift支持泛型，而OC仅支持轻量级的泛型
Swift的协议可以用于类，结构体和枚举，而OC协议只能用于类
Swift没有正则，但是可以使用OC的正则，swift中有模式匹配
Swift的枚举功能强大，可以添加函数等，而OC的枚举和c差不多
Swift支持命名空间，而OC 没有
Swift支持运算符重载，有元组类型等

# 3.类和结构体的区别
相同点：

* 定义存储属性
* 定义方法
* 定义下标语法以存取变量
* 定义初始化器以初始化变量
* 定义扩展
* 可以遵守协议

不同点：
* 类是引用类型，结构体是值类型
* 类可以继承，而结构体不行
* 类有类型转换，类型转换能够在运行时检查和解释类实例的类型
* 类有析构方法
* 类有引用计数
* 结构体如果没有自定义的初始化器会获得一个memberwise initializer
* 类的内存分配到堆上,类的引用变量分配到栈上，而结构体内存分配到栈上

# 4.高阶函数
高阶函数是一种以函数为参数的函数。

* map: 对每个元素进行变形后返回一个新的集合
* filter: 根据过滤条件返回新的集合
* reduce: 在给定的序列上产生一个唯一的值，比如累加或累乘
* sort: 对给定的序列排序
* flatMap: 当对每个元素的转换产生一个序列时会把序列展平，最后结果只产生一个序列
* compactMap: 过滤nil元素

# 5.swift方法派发类型
* 直接派发（静态派发）：final, static, @inline，值类型
* 函数表派发（动态派发）：
* 消息派发：dynamic, @objc

![派发方式](media/16805746480791/img_v2_dd9b17a2-0c2d-4d87-8b5c-a38847078f9g.webp)

# 6.dynamic 的作用

由于 swift 是一个静态语言, 所以没有 Objective-C 中的消息发送这些动态机制, dynamic 的作用就是让 swift 代码也能有 Objective-C 中的动态机制

# 7.什么时候使用 @objc

* target-action，通知等
* OC 调用swift代码，swift的属性 方法等需要加
* swift协议设置可选时

# 8.什么是copy on write

“写时复制”指的是一种机制，用于优化对值类型(如数组、字符串和字典)的某些操作的性能，当它们以允许它们被多个引用共享的方式使用时，通过避免值类型的不必要的复制来提高性能。它是标准库中的功能，swift语言中不存在。

# 9.Swift中的访问控制权限

* Open：实体可被同一模块内所有实体访问，模块外可导入该模块即可访问，模块外可被继承和重写。
* Public：实体可被同一模块内所有实体访问，模块外可导入该模块即可访问，模块外不能被继承和重写。
* Internal：实体可被同一模块内所有实体访问，模块外无法访问，大部分实体默认是Internal级别。
* fileprivate:限制实体只能在当前文件内访问到，不管是否在本类的作用域。
* private: 限制实体只能在本类的作用域且在当前文件内能访问。

# 10. Any和AnyObject

Any 和 AnyObject 是swift提供的两个非具体的类型
* Any: 代表任务类型的实例，包括函数
* AnyObject:只能代表类的实例
 
# 11. lazy使用的场景

* 标识一个存储属性为lazy,存储属性只能用var修饰
* 数组或序列的lazy属性

        let evens = (1...10).lazy

              .filter { $0.isMultiple(of: 2) }
              
              .filter { print($0); return true }
              
        evens.first // 只打印2，其余的未访问，不会打印

* 全局变量和常量都是延时计算的，不用明确写上lazy，局部变量和常量都不是延时计算的

# 12. 闭包的种类

尾随闭包: 闭包作为函数参数的最后一个参数，可以写在（）之后，5.3开始支持多尾随闭包
逃逸闭包: 闭包不在函数内同步执行(@escaping)
自动闭包: 用@autoclosure修饰的无参闭包，返回值是表达式的值

# 13. swift 常见的协议

Hashable:
Comparable:
Equatable:
Strideable:
ExpressibleByArrayLiteral:
ExpressibleByNilLiteral:

# 14. swift 延迟初始化的例子

一个是在init方法里初始存储属性
一个是在函数里定义一个变量，然后再使用之前初始化变量

# 15. 下面的结果是什么

a?只在非nil情况下生效

    var a: Int?
    a? = 10 // nil
    a = 10 // 10

    var dictWithNils: [String: Int?] = [:]
    dictWithNils["three"]? = nil
    dictWithNils.index(forKey: "three") // nil
    
    
    