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
    
    
# 16. Swift 协程（Concurrency）

Swift 5.5 引入 async/await，后续版本持续增强，到 Swift 6.3/6.4 日臻完善。

## 16.1 async / await

```swift
// async 函数：可被暂停和恢复的异步函数
func fetchImage(url: URL) async throws -> UIImage {
    let (data, response) = try await URLSession.shared.data(from: url)
    guard let image = UIImage(data: data) else {
        throw URLError(.badServerResponse)
    }
    return image
}

// 调用：使用 await 等待异步结果
Task {
    do {
        let image = try await fetchImage(url: url)
        imageView.image = image
    } catch {
        print("Failed: \(error)")
    }
}
```

### async 函数的执行特性

- `async` 函数可以被**暂停**（suspended），但不会阻塞线程
- 暂停期间线程可以执行其他任务
- `await` 是可能的暂停点（suspension point）
- 恢复执行时不一定回到原线程

## 16.2 Task（任务）

Task 是 Swift 并发的基本单元，代表一个异步工作单元：

```swift
// 创建 Task（在当前 actor 上运行）
Task {
    let result = await someAsyncFunction()
}

// detached task（不在当前 actor 上运行）
Task.detached {
    let result = await someAsyncFunction()
}

// 获取返回值
let handle: Task.Handle<Data, Error> = Task {
    return try await fetchData()
}
let data = try await handle.value

// Task 优先级
Task(priority: .high) { ... }
Task(priority: .background) { ... }
```

### Task 的状态

```
       ┌──────────┐
       │  Suspended│ ◄──── 等待 await（不阻塞线程）
       └────┬─────┘
            │
    ┌───────▼────────┐
    │   Executing    │
    └───────┬────────┘
            │
    ┌───────▼────────┐
    │   Completed    │
    └────────────────┘
```

## 16.3 TaskGroup（任务组）

创建多个并行子任务，等待全部完成：

```swift
// 并行下载多张图片
func fetchImages(urls: [URL]) async throws -> [UIImage] {
    try await withThrowingTaskGroup(of: UIImage.self) { group in
        for url in urls {
            group.addTask {
                return try await fetchImage(url: url)
            }
        }

        var images: [UIImage] = []
        for try await image in group {
            images.append(image)
        }
        return images
    }
}
```

**TaskGroup 特性**：
- 所有子任务并行执行
- 自动等待所有子任务完成
- 任一子任务抛异常，整个 group 取消
- 支持 `withTaskGroup`（不抛异常）和 `withThrowingTaskGroup`

## 16.4 Actor（参与者）

Actor 保护可变状态免受数据竞争：

```swift
actor BankAccount {
    private var balance: Double = 0

    func deposit(amount: Double) {
        balance += amount
    }

    func withdraw(amount: Double) -> Bool {
        if balance >= amount {
            balance -= amount
            return true
        }
        return false
    }

    func getBalance() -> Double {
        return balance
    }
}

// 使用：await 跨 actor 调用
let account = BankAccount()
await account.deposit(amount: 100)
let success = await account.withdraw(amount: 30)
print(await account.getBalance()) // 70
```

**Actor 的特性**：
- 所有方法默认是 `async` 的（跨 actor 调用需要 await）
- Actor 自己可以同步访问自己的属性
- 编译器保证 actor 隔离（Actor Isolation）
- 避免传统锁的竞态条件和死锁

### MainActor

专门用于主线程的 actor：

```swift
@MainActor
class ViewModel: ObservableObject {
    @Published var name: String = ""

    func updateName(_ newName: String) {
        // 保证在主线程执行
        self.name = newName
    }
}

// 在非主线程调用
Task { @MainActor in
    // 切换到主线程执行
    viewModel.updateName("Alice")
}
```

## 16.5 Sendable（可发送协议）

Sendable 标记类型可以安全地在并发域之间传递：

```swift
// 值类型自动满足 Sendable
struct User: Sendable {
    let id: Int
    let name: String
}

// 引用类型需要显式标记
final class SafeConfig: @unchecked Sendable {
    let apiKey: String // 不可变属性是安全的
}

// ⚠️ 非 Sendable 类型在并发传递时编译器会警告
```

**Swift 6 严格并发检查**：Swift 6 模式下，跨 actor 传递非 Sendable 类型会编译错误。

## 16.6 async let（异步绑定）

创建立即开始的异步子任务，后续 await 结果：

```swift
// 并行执行三个异步操作
async let user = fetchUser()
async let posts = fetchPosts()
async let friends = fetchFriends()

// 等待所有结果，三个任务并行执行
let (userData, postsData, friendsData) = try await (user, posts, friends)
```

## 16.7 async 序列（AsyncSequence）

异步产生多个值的序列：

```swift
// 异步序列的定义
struct Counter: AsyncSequence {
    typealias Element = Int
    let count: Int

    struct AsyncIterator: AsyncIteratorProtocol {
        var current = 0
        let count: Int

        mutating func next() async -> Int? {
            guard current < count else { return nil }
            defer { current += 1 }
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            return current
        }
    }

    func makeAsyncIterator() -> AsyncIterator {
        return AsyncIterator(count: count)
    }
}

// for-await-in 循环
for await number in Counter(count: 5) {
    print(number) // 每秒输出 0, 1, 2, 3, 4
}
```

---

# 17. Swift 6.3 新增知识点

Swift 6.3 于 2026 年 3 月发布，主要新增以下特性：

## 17.1 @c 属性 — Swift/C 互操作

将 Swift 函数和枚举暴露给 C 代码：

```swift
@c
func callFromC() { print("Called from C!") }

// 生成 C 头文件中的声明：
// void callFromC(void);

// 自定义 C 函数名
@c(MyLibrary_initialize)
func initialize() { ... }

// 与 @implementation 配合，实现 C 头文件中声明的函数
@c @implementation
func callFromC() { ... }
```

## 17.2 模块选择器（Module Selectors）

用 `::` 消除跨模块的命名冲突：

```swift
import ModuleA
import ModuleB

let x = ModuleA::getValue()  // 明确指定用 ModuleA 的 getValue
let y = ModuleB::getValue()  // 明确指定用 ModuleB 的 getValue

// 也可以访问 Swift 标准库
let task = Swift::Task { ... }
```

## 17.3 库 API 性能控制

```swift
// @specialize：为特定类型预生成特化版本
struct Container<Element> {
    @specialize(where Element == Int)
    @specialize(where Element == String)
    mutating func append(_ element: Element) { ... }
}

// @inline(always)：强制内联（需配合 final）
final class MathUtils {
    @inline(always)
    static func square(_ x: Int) -> Int { x * x }
}

// @export(implementation)：暴露实现给库使用者
@export(implementation)
func computeHeavy() -> Data { ... }
```

## 17.4 包管理与构建工具

- **Swift Build**：统一构建引擎预览版
- **预编译 swift-syntax**：共享宏库的二进制支持
- **包特性发现**：`swift package show-traits`
- **Android 官方 SDK**：首个正式版 Swift SDK for Android

## 17.5 Swift Testing 改进

```swift
// 警告级别 Issue
Issue.record("疑似问题", severity: .warning)  // 不影响测试通过

// 测试取消
try Test.cancel()  // 在测试中主动取消

// 图片附件（UIKit/SwiftUI）
#Attachment(image: screenshot)  // 附加图片到测试报告
```

## 17.6 DocC 新能力

```swift
// Markdown 输出
// docc convert --enable-experimental-markdown-output

// 代码块注释
// ```swift, nocopy, highlight=[1,3], showLineNumbers, wrap=80
```

---

# 18. Swift 6.4 新增知识点（WWDC 2026）

Swift 6.4 与 6.3 在 WWDC26 同期发布，侧重协程生命周期完善和所有权系统落地。

## 18.1 async 在 defer 块中（SE-0493）

```swift
func processFile() async throws {
    let handle = try await openFile()
    defer {
        // ✅ Swift 6.4：defer 中支持 async 调用
        // await handle.close()
    }
    try await process(handle)
    // defer 自动执行清理
}
```

## 18.2 Task Cancellation Shield（SE-0504）

保护关键清理操作不被取消打断：

```swift
try await withTaskCancellationShield {
    // 取消检查在此区域内始终返回 false
    // 确保关键的写磁盘操作完成
    try await finishWritingToDisk()
}
// 区域外恢复正常取消行为
```

## 18.3 weak let 支持 Sendable

```swift
class Child {
    weak let parent: Parent?  // ✅ 现在 weak let 不会阻止 Sendable
    init(parent: Parent?) {
        self.parent = parent
    }
}
// 不再需要 @unchecked Sendable
```

## 18.4 ~Sendable 语法

显式标记类型不可发送：

```swift
struct MutableBuffer: ~Sendable {
    var pointer: UnsafeMutableRawPointer
}
// 明确告诉编译器这个类型不能在并发域间传递
```

## 18.5 Iterable 协议

新的 for 循环协议，借用元素而非拷贝：

```swift
// Iterable 协议特性：
// - 借用元素（borrow），无引用计数开销
// - 支持非可拷贝元素
// - 可 throw
// - 批量返回元素（span）

// for 循环优先使用 Iterable，fallback 到 Sequence
let buffer: UniqueArray<SomeValue>
for element in buffer {
    // element 是借用（borrow），不是拷贝
    process(element)
}
```

## 18.6 borrow / mutate 访问器

对计算属性实现借用和修改，替代 get/set：

```swift
struct LargeStruct {
    var x: Int
    var y: Int
    // ...
}

struct Container {
    var _storage: LargeStruct

    var storage: LargeStruct {
        borrow { _storage }     // 只读借用，无拷贝
        mutate { &_storage }    // 原地修改，无拷贝
    }
}
```

## 18.7 新标准库类型

```swift
// UniqueArray：非可拷贝数组，存储非可拷贝元素
var array = UniqueArray<FileDescriptor>()

// Continuation：安全的单次 resume 回调
// 编译时检查是否恰好 resume 一次，性能等同于 UnsafeContinuation
let result = try await withContinuation { continuation in
    // continuation 只能被 resume 一次
}

// Ref / MutableRef：可存储的借用/修改容器
func process(_ ref: Ref<String>) { ... }
```

## 18.8 并发相关改进总结

| 特性 | 版本 | 说明 |
|------|------|------|
| async in defer | 6.4 | defer 块支持 async 调用 |
| withTaskCancellationShield | 6.4 | 保护关键操作不被取消 |
| weak let Sendable | 6.3 | weak let 类型可通过 Sendable 检查 |
| ~Sendable 语法 | 6.3 | 显式标记非 Sendable 类型 |
| @diagnose 严格并发 | 6.4 | 按声明粒度控制并发诊断 |
| ProgressManager | 6.4 | 基于 async/await 的进度上报 |
| Subprocess 1.0 | 6.4 | 基于 AsyncSequence 的子进程输出 |