# Swift Concurrency 详解

Swift Concurrency 是 Swift 5.5+ 引入的原生并发编程框架，通过 async/await、Task、Actor 等提供结构化并发能力。

---

## 一、async / await

### 1.1 基本语法

```swift
// 定义异步函数
func fetchUser(id: Int) async throws -> User {
    let url = URL(string: "https://api.example.com/users/\(id)")!
    let (data, response) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode(User.self, from: data)
}

// 调用异步函数
Task {
    do {
        let user = try await fetchUser(id: 1)
        print(user.name)
    } catch {
        print("Failed: \(error)")
    }
}
```

### 1.2 async 函数的特点

```
async 函数的执行模型：

  ① 开始执行（同步）
      │
  ② 遇到 await → 暂停当前函数（suspension point）
      │               → 线程可以执行其他任务
      │
  ③ 异步操作完成 → 系统调度恢复执行
      │               → 不一定回到原线程
      │
  ④ 继续执行剩余代码
```

**关键点**：
- `await` 是**暂停点（suspension point）**，不是阻塞
- 暂停期间**不占用线程**，线程可以去执行其他任务
- 恢复执行时**不一定回到原来的线程**
- 这比 GCD 更高效（GCD 的 Block 会 block 线程）

### 1.3 异步函数类型

```swift
// 1. 抛出异常的异步函数
func fetchData() async throws -> Data

// 2. 不抛出异常的异步函数
func fetchName() async -> String

// 3. 无返回值的异步函数
func logEvent() async

// 4. 异步属性
var status: Status {
    get async { await fetchStatus() }
}

// 5. 异步下标
subscript(_ index: Int) -> Item {
    get async { await fetchItem(at: index) }
}
```

### 1.4 异步序列（AsyncSequence）

```swift
// 异步序列：用 for-await-in 遍历
for await line in fileHandle.lines {
    print(line)  // 逐行处理，每行到达时异步等待
}

// 自定义 AsyncSequence
struct Counter: AsyncSequence {
    typealias Element = Int
    let limit: Int

    struct AsyncIterator: AsyncIteratorProtocol {
        var current = 0
        let limit: Int

        mutating func next() async -> Int? {
            guard current < limit else { return nil }
            defer { current += 1 }
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            return current
        }
    }

    func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(limit: limit)
    }
}
```

---

## 二、Task

### 2.1 Task 的基本概念

Task 是 Swift Concurrency 的基本执行单元，代表一个**可独立执行的异步工作单元**。

```
Task 的生命周期：
  创建（Task { }）→ 挂起（await）→ 执行 → 完成（返回结果/抛出错误/取消）
```

### 2.2 创建 Task

```swift
// 1. 常规 Task（继承当前上下文）
Task {
    let data = try await fetchData()
    await MainActor.run {
        self.label.text = data
    }
}

// 2. 带返回值的 Task
let handle: Task.Handle<Data, Error> = Task {
    return try await downloadFile()
}
let data = try await handle.value  // 等待 Task 完成并获取结果

// 3. 指定优先级的 Task
Task(priority: .high) {
    // 高优先级任务
}

Task(priority: .background) {
    // 后台任务
}

// 4. Detached Task（不继承上下文，独立运行）
Task.detached {
    // 不继承父 Task 的优先级、Actor 上下文等
    await someAsyncFunction()
}
```

### 2.3 Task 优先级

```swift
// 优先级从高到低：
Task(priority: .high)      // userInteractive
Task(priority: .medium)    // 默认
Task(priority: .low)       // utility
Task(priority: .background) // background

// 子 Task 默认继承父 Task 的优先级
Task {
    Task {  // 继承父 Task 的优先级
        // ...
    }
}
```

### 2.4 Task 取消

```swift
let task = Task {
    // 检查取消状态
    try Task.checkCancellation()  // 已取消则抛出 CancellationError

    // 或者主动检查
    guard !Task.isCancelled else { return }

    // 执行任务
    for i in 0..<100 {
        try Task.checkCancellation()  // 在循环中定期检查
        await processItem(i)
    }
}

// 取消 Task
task.cancel()
```

### 2.5 Task 休眠

```swift
// Task 休眠（不阻塞线程）
try await Task.sleep(nanoseconds: 1_000_000_000)  // 1 秒
try await Task.sleep(for: .seconds(1))            // Swift 5.7+ 语法糖
try await Task.sleep(until: .now + .seconds(5))   // 休眠到指定时间
```

### 2.6 Task 本地值

```swift
// Task 本地值：在当前 Task 及其子 Task 中传递数据
enum TaskLocals {
    @TaskLocal static var requestId: String = ""
    @TaskLocal static var userId: Int = 0
}

Task.$requestId.withValue("req-123") {
    Task {  // 子 Task 自动继承父 Task 的本地值
        print(TaskLocals.requestId)  // "req-123"
    }
}
```

---

## 三、TaskGroup

### 3.1 基本用法

```swift
// 并行执行多个子任务
let results = try await withThrowingTaskGroup(of: Data.self) { group in
    for url in urls {
        group.addTask {
            return try await download(url: url)
        }
    }

    var dataArray = [Data]()
    for try await result in group {
        dataArray.append(result)
    }
    return dataArray
}
```

### 3.2 withTaskGroup vs withThrowingTaskGroup

```swift
// 不会抛出错误的 TaskGroup
let sum = await withTaskGroup(of: Int.self) { group in
    for i in 1...10 {
        group.addTask {
            return i * i
        }
    }

    var total = 0
    for await result in group {
        total += result
    }
    return total
}

// 会抛出错误的 TaskGroup
let datas = try await withThrowingTaskGroup(of: Data.self) { group in
    // 任一子 Task 抛出错误，整个 group 取消
    for url in urls {
        group.addTask {
            return try await download(url: url)
        }
    }
    // ...
}
```

### 3.3 子 Task 返回值和错误处理

```swift
let results = try await withThrowingTaskGroup(of: Result<Data, Error>.self) { group in
    for url in urls {
        group.addTask {
            do {
                let data = try await download(url: url)
                return .success(data)
            } catch {
                return .failure(error)  // 将错误封装到 Result，不影响其他任务
            }
        }
    }

    var datas = [Data]()
    for try await result in group {
        if case .success(let data) = result {
            datas.append(data)
        }
    }
    return datas
}
```

### 3.4 动态添加子 Task

```swift
// TaskGroup 支持在子 Task 中再添加子 Task
try await withThrowingTaskGroup(of: Void.self) { group in
    group.addTask {
        try await withThrowingTaskGroup(of: Void.self) { subGroup in
            for item in subItems {
                subGroup.addTask {
                    try await process(item)
                }
            }
        }
    }
    // ...
}
```

### 3.5 async let（隐式 TaskGroup）

```swift
// async let 是创建并行子 Task 的简写语法
async let user = fetchUser()
async let posts = fetchPosts()
async let friends = fetchFriends()

// 三个任务并行执行
let (userData, postsData, friendsData) = try await (user, posts, friends)
```

---

## 四、Actor

### 4.1 Actor 的基本概念

Actor 是 Swift 中保护可变状态免受数据竞争的机制。**同一时间只有一个 Task 可以访问 Actor 的内部状态**。

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

// 使用
let account = BankAccount()
await account.deposit(amount: 100)
let balance = await account.getBalance()
```

### 4.2 Actor 隔离规则

```swift
actor Counter {
    var value = 0

    // 同步方法：只能在 Actor 内部调用
    func increment() {
        value += 1  // ✅ Actor 内部可以直接访问
    }

    // 异步方法：外部调用需 await
    func getValue() -> Int {
        return value
    }
}

// 外部调用
let counter = Counter()
await counter.increment()
let v = await counter.getValue()

// 在 Actor 内部调用另一个 Actor 的方法
actor Logger {
    func log(_ message: String) {
        print(message)
    }
}

actor DataManager {
    let logger = Logger()

    func save() async {
        await logger.log("Saving...")  // ✅ 跨 Actor 需要 await
    }
}
```

### 4.3 nonisolated

```swift
actor MyActor {
    let name: String = "MyActor"  // let 属性天然安全

    // nonisolated：不参与 Actor 隔离
    nonisolated func getName() -> String {
        return name  // 调用时不需要 await
    }

    // 可以在非 Actor 环境中直接调用
    // let name = myActor.getName()  // ✅ 不需要 await
}
```

### 4.4 MainActor

`MainActor` 是专门运行在主线程的 Actor：

```swift
@MainActor
class ViewModel: ObservableObject {
    @Published var name: String = ""

    func updateName(_ newName: String) {
        // 保证在主线程执行
        self.name = newName
    }
}

// 确保 UI 更新在主线程
Task { @MainActor in
    self.label.text = "Updated"
}

// 函数级别的 MainActor
@MainActor
func updateUI() {
    // 此函数始终在主线程执行
}

// 全局属性
@MainActor
var appState: AppState = .initial
```

### 4.5 Actor 的死锁预防

Actor 是**可重入的（reentrant）**：

```swift
actor DataLoader {
    func loadData() async -> Data {
        // 在 await 之前，Actor 持有锁
        let data = await fetchFromNetwork()
        // 在 await 期间，Actor 释放锁，其他 Task 可以进入
        return process(data)
        // 恢复执行后，重新获取锁
    }
}
```

**重要**：Actor 在 `await` 时会**暂停当前 Task 并释放 Actor 锁**，其他 Task 可以在此期间进入该 Actor。这**避免了死锁**，但需要注意数据状态在 await 前后可能发生变化。

### 4.6 Sendable

`Sendable` 协议标记可以在并发域之间安全传递的类型：

```swift
// 值类型自动满足 Sendable
struct User: Sendable {
    let id: Int
    let name: String
}

// 类需要显式标记
final class SafeConfig: @unchecked Sendable {
    let apiKey: String
    init(apiKey: String) {
        self.apiKey = apiKey
    }
}

// 跨 Actor 传递 Sendable 类型不会产生警告
actor UserManager {
    func update(_ user: User) {  // ✅ User 是 Sendable
        // ...
    }
}
```

---

## 五、结构化并发

### 5.1 什么是结构化并发

结构化并发是指：**子 Task 的生命周期被限制在父 Task 的作用域内**。

```
非结构化并发：
  Task { }     → 独立于当前作用域，没有父子关系
  Task.detached { } → 完全独立

结构化并发：
  withTaskGroup { }  → 子 Task 在 group 结束时必须完成
  async let          → 子 Task 在作用域结束时必须完成
```

### 5.2 结构化并发的原则

```
1. 子 Task 不能比父 Task 活得更长
2. 父 Task 等待所有子 Task 完成后才结束
3. 子 Task 继承父 Task 的优先级和 Actor 上下文
4. 子 Task 取消自动传播
```

### 5.3 非结构化并发

```swift
// 非结构化 Task：不绑定到父作用域
func fireAndForget() {
    Task {  // 此 Task 独立于当前函数
        await longRunningTask()
    }
    // 函数返回后，Task 仍在执行
}
```

### 5.4 取消传播

```swift
// 取消会从父 Task 传播到所有子 Task
let parentTask = Task {
    await withThrowingTaskGroup(of: Void.self) { group in
        group.addTask {
            try await longRunningTask1()  // 父 Task 取消时，自动取消
        }
        group.addTask {
            try await longRunningTask2()  // 同上
        }
    }
}

parentTask.cancel()  // 取消所有子 Task
```

---

## 六、Continuation

### 6.1 桥接回调式 API

```swift
// 将回调式 API 包装为 async/await
func fetchUser(completion: @escaping (Result<User, Error>) -> Void) {
    // 旧式回调 API
}

// 用 Continuation 包装
func fetchUser() async throws -> User {
    return try await withCheckedContinuation { continuation in
        fetchUser { result in
            continuation.resume(with: result)
        }
    }
}
```

### 6.2 CheckedContinuation vs UnsafeContinuation

```swift
// CheckedContinuation（推荐）：运行时会检查 resume 是否被调用恰好一次
func fetch() async throws -> Data {
    return try await withCheckedContinuation { continuation in
        callbackAPI { data, error in
            if let error = error {
                continuation.resume(throwing: error)
            } else {
                continuation.resume(returning: data)
            }
        }
    }
}

// UnsafeContinuation（高性能，不做检查）
func fetchFast() async throws -> Data {
    return try await withUnsafeContinuation { continuation in
        callbackAPI { data, error in
            continuation.resume(with: .success(data))
        }
    }
}
```

### 6.3 注意事项

```swift
// ❌ 错误：多次调用 resume
withCheckedContinuation { continuation in
    callbackAPI { result in
        continuation.resume(returning: result)  // 第一次
        continuation.resume(returning: result)  // ❌ 运行时崩溃
    }
}

// ❌ 错误：没有调用 resume
withCheckedContinuation { continuation in
    // 忘记调用 continuation.resume() → 运行时警告
    // Task 永远挂起，无法释放
}

// ✅ 正确：确保每个路径都调用一次 resume
withCheckedContinuation { continuation in
    if condition {
        continuation.resume(returning: value)
    } else {
        continuation.resume(returning: defaultValue)
    }
}
```

---

## 七、Global Actors

### 7.1 自定义全局 Actor

```swift
// 自定义全局 Actor
@globalActor
actor DatabaseActor {
    static let shared = DatabaseActor()
}

// 使用自定义全局 Actor
@DatabaseActor
class DatabaseManager {
    func read() -> [Record] { ... }
    func write(_ record: Record) { ... }
}

// 函数级别使用
@DatabaseActor
func performDatabaseOperation() async {
    // 确保在 DatabaseActor 上执行
}
```

### 7.2 @MainActor 原理

```swift
// MainActor 的定义本质就是一个全局 Actor
@globalActor actor MainActor {
    static let shared = MainActor()
}

// 等价于
DispatchQueue.main.async {
    // UI 操作
}
// 但现在由编译器保证，而非手动
```

---

## 八、Swift Concurrency vs GCD 对比

| 维度 | GCD | Swift Concurrency |
|------|-----|-------------------|
| **语法** | Block 回调 | sync 风格 async/await |
| **线程管理** | 系统线程池（线程级） | 协作式调度（任务级） |
| **上下文切换** | 手动 | 编译器自动处理 |
| **线程安全** | 需手动加锁 | Actor 自动隔离 |
| **任务取消** | ❌ 无法取消单个 Block | ✅ Task.cancel() |
| **任务依赖** | ❌ 不支持（NSOperation 支持） | ✅ TaskGroup + async let |
| **数据竞争保护** | ❌ 需要 @synchronized | ✅ Actor + Sendable |
| **性能** | 线程切换开销较大 | 协作式，更轻量 |
| **调试** | 复杂 | 结构化，清晰 |
| **学习成本** | 低 | 较高 |
| **适用场景** | 简单异步、兼容旧代码 | 新项目、复杂并发 |

---

## 九、面试题

### 1. async/await 和 GCD 的区别？

async/await 是**协作式调度**（任务挂起时不占线程），GCD 是**抢占式调度**（Block 所在的线程被阻塞）。async/await 更高效，不会浪费线程资源。

### 2. Task 和 DispatchQueue 的区别？

Task 是 Swift 原生并发的执行单元，支持取消、优先级继承、Actor 隔离。DispatchQueue 是 GCD 的队列，任务是 Block，不支持取消和结构化并发。

### 3. Actor 和 Class 的区别？

Actor 保证同一时间只有一个 Task 能修改其内部状态（编译器强制），Class 需要手动加锁保护。

### 4. Sendable 的作用？

标记类型可以安全地在并发域之间传递。值类型默认 Sendable，引用类型需要显式标记。

### 5. async let 和 TaskGroup 的区别？

- `async let`：简写，适合固定数量的并行任务
- `TaskGroup`：灵活，适合动态数量的并行任务，支持动态添加子 Task

### 6. MainActor.run 和 DispatchQueue.main.async 的区别？

- `MainActor.run`：编译时保证在主线程执行，支持 await 返回值
- `DispatchQueue.main.async`：运行时保证，Block 不能直接 await

### 7. 什么是结构化并发？

子 Task 的生命周期被限制在父作用域内，父 Task 等待所有子 Task 完成，取消自动传播。

### 8. withCheckedContinuation 的作用？

将回调式的异步 API 桥接为 async/await 风格。Checked 版本会在运行时检查 resume 是否恰好调用一次。

### 9. Swift Concurrency 中如何做超时控制？

```swift
// 用 withTimeout 或 TaskGroup 实现超时
try await withThrowingTaskGroup(of: Data.self) { group in
    group.addTask {
        return try await fetchData()
    }
    group.addTask {
        try await Task.sleep(nanoseconds: 5_000_000_000)
        throw TimeoutError()
    }

    let result = try await group.next()!  // 谁先完成就用谁
    group.cancelAll()  // 取消另一个 Task
    return result
}
```

### 10. Swift Concurrency 的最佳实践

1. 新项目优先使用 Swift Concurrency 而非 GCD
2. 使用 Actor 保护可变状态而非手动加锁
3. 使用结构化并发（TaskGroup / async let）而非 Task.detached
4. 使用 `@unchecked Sendable` 仅在确定安全时
5. 使用 Continuation 桥接旧式回调 API
6. 所有 UI 操作放在 `@MainActor` 中
7. 避免在 Actor 中做耗时同步操作（会阻塞 Actor）
8. 使用 `TaskLocal` 传递请求上下文而非全局变量

---

## 参考

- [Swift Concurrency 官方文档](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [WWDC 2021 - Meet async/await in Swift](https://developer.apple.com/videos/play/wwdc2021/10132/)
- [WWDC 2021 - Protect mutable state with Swift actors](https://developer.apple.com/videos/play/wwdc2021/10133/)
