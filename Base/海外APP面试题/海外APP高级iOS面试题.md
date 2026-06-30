# 海外 App（Premom）高级 iOS 面试题

## 岗位关键词

Swift / OC / 多线程 / 锁 / 内存管理 / Flutter 混合开发 / 从 0 到 1 架构 / 业务重构 / 性能监控 / 底层原理 / 组件化 / 性能优化 / Socket / TCP/IP / HTTP / SQLite / AI 工具 / 英语沟通

---

## 一、Swift 核心

### 1. Swift 中 struct 和 class 的区别是什么？什么场景用 struct？

| 维度 | struct | class |
|------|--------|-------|
| 类型 | 值类型 | 引用类型 |
| 内存 | 栈上（内联优化） | 堆上 |
| 继承 | ❌ 不支持 | ✅ 支持 |
| 可变性 | 需 `mutating` 修改属性 | 可直接修改 |
| 引用计数 | ❌ 无 | ✅ ARC 管理 |
| 线程安全 | ✅ 天然安全（拷贝隔离） | ❌ 需注意 |

**场景建议**：
- 模型数据（`Codable` 模型）→ `struct`
- 需要继承或共享状态 → `class`
- 轻量包装 → `struct`
- 需要 `deinit` → `class`

### 2. Swift 的 optional 底层实现是什么？

```swift
enum Optional<Wrapped> {
    case none
    case some(Wrapped)
}
```

- `Optional` 本质是一个**枚举**
- `nil` 就是 `Optional.none`
- `!` 是强制解包，为 nil 时崩溃
- `??` 是空值合并运算符
- `?` 是语法糖，编译器自动包装为 Optional

### 3. Swift 中 map、flatMap、compactMap、filter、reduce 的区别

```swift
let numbers = [1, 2, 3, nil, 4, nil, 5]

numbers.map { $0 }                // [Optional(1), Optional(2), ..., nil]
numbers.compactMap { $0 }         // [1, 2, 3, 4, 5]（过滤 nil）
numbers.flatMap { [$0, $0] }      // 展平：每个元素变数组再合并
numbers.filter { $0 ?? 0 > 2 }    // 过滤条件
numbers.reduce(0, +)              // 归约：累加
```

### 4. Swift 属性包装器（@propertyWrapper）是什么？用过哪些？

```swift
@propertyWrapper
struct Clamping<T: Comparable> {
    var value: T
    let range: ClosedRange<T>

    var wrappedValue: T {
        get { value }
        set { value = min(max(range.lowerBound, newValue), range.upperBound) }
    }
}

// 内置 @propertyWrapper
@State        // SwiftUI 状态
@Binding      // SwiftUI 绑定
@Published    // Combine 发布
@AppStorage   // UserDefaults 存储
@Environment  // 环境值
```

### 5. Swift 柯里化（Currying）的使用场景是什么？

柯里化是将一个接受多个参数的函数，转换为一系列接受单个参数的函数。

```swift
// 非柯里化
func add(_ a: Int, _ b: Int) -> Int { a + b }

// 柯里化
func add(_ a: Int) -> (Int) -> Int {
    return { b in a + b }
}

let add5 = add(5)     // 先固定第一个参数
add5(3)               // 8
add5(10)              // 15
```

**使用场景**：

| 场景 | 示例 | 说明 |
|------|------|------|
| **依赖注入** | `network.fetchUsers(token)()` | 先注入 token，再调用请求 |
| **配置复用** | `format(with: style)("text")` | 先配置格式，再格式化文本 |
| **链式 DSL** | `view.frame(x:)(y:)(width:)(height:)` | 逐步配置对象属性 |
| **函数组合** | `(map >>> filter >>> reduce)(data)` | 组合多个转换步骤 |

```swift
// 场景 1：网络请求的 token 注入
class API {
    func request(_ token: String) -> (_ endpoint: String) -> (_ params: [String: Any]) -> Any {
        return { endpoint in
            return { params in
                // 使用 token 发起请求
                return ["data": "result"]
            }
        }
    }
}

let api = API()
let authenticated = api.request("bearer_token")  // 全局注入一次
let userData = authenticated("/users")(["id": 1]) // 后续请求不需要重新传 token

// 场景 2：UI 配置（类似 SwiftUI 的 modifier 链）
func configure<T>(_ object: T) -> ((T) -> Void) -> T {
    return { config in
        config(object)
        return object
    }
}

let label = configure(UILabel()) { label in
    label.text = "Hello"
    label.textColor = .red
    label.font = .systemFont(ofSize: 16)
}
```

**注意**：Swift 中柯里化的使用不如函数式语言（Haskell）广泛，因为 Swift 有更好的替代方案（默认参数、闭包、链式调用）。**面试中问到此题，重点在于考查对函数式编程思想的理解。**

---

### 6. Swift 柯里化的实际应用有哪些？（生产级案例）

#### 实际应用 1：网络层拦截器链

```swift
// 柯里化实现网络拦截器管道
typealias Interceptor = (@escaping (URLRequest) -> Void) -> (URLRequest) -> Void

// 日志拦截器
func logInterceptor(next: @escaping (URLRequest) -> Void) -> (URLRequest) -> Void {
    return { request in
        print("[Request] \(request.url?.absoluteString ?? "")")
        let start = CACurrentMediaTime()
        next(request)
        let duration = (CACurrentMediaTime() - start) * 1000
        print("[Response] \(String(format: "%.1fms", duration))")
    }
}

// Token 拦截器
func tokenInterceptor(token: String, next: @escaping (URLRequest) -> Void) -> (URLRequest) -> Void {
    return { request in
        var mutableRequest = request
        mutableRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        next(mutableRequest)
    }
}

// 重试拦截器
func retryInterceptor(maxRetry: Int, next: @escaping (URLRequest) -> Void) -> (URLRequest) -> Void {
    return { request in
        func attempt(_ retryCount: Int) {
            next(request)
            // 失败时递归重试
        }
        attempt(0)
    }
}

// 组合使用：先注入 token，再添加日志，最后设置重试
let pipeline = logInterceptor(next:
    tokenInterceptor(token: "my_token", next:
        retryInterceptor(maxRetry: 3, next: { request in
            URLSession.shared.dataTask(with: request) { data, _, _ in
                // handle response
            }.resume()
        })
    )
)
pipeline(URLRequest(url: URL(string: "https://api.example.com")!))
```

#### 实际应用 2：链式 DSL 构建 UI 组件

```swift
// 柯里化构建链式 UI 配置器
final class LabelBuilder {
    static func text(_ text: String) -> (UILabel) -> UILabel {
        return { label in
            label.text = text
            return label
        }
    }

    static func font(_ font: UIFont) -> (UILabel) -> UILabel {
        return { label in
            label.font = font
            return label
        }
    }

    static func color(_ color: UIColor) -> (UILabel) -> UILabel {
        return { label in
            label.textColor = color
            return label
        }
    }

    static func align(_ alignment: NSTextAlignment) -> (UILabel) -> UILabel {
        return { label in
            label.textAlignment = alignment
            return label
        }
    }
}

// 定义可组合的构建器
infix operator >>>: AdditionPrecedence
func >>> <T>(lhs: @escaping (T) -> T, rhs: @escaping (T) -> T) -> (T) -> T {
    return { x in rhs(lhs(x)) }
}

// 组合多个配置
let titleStyle = LabelBuilder.text("Hello")
    >>> LabelBuilder.font(.boldSystemFont(ofSize: 18))
    >>> LabelBuilder.color(.black)
    >>> LabelBuilder.align(.center)

// 应用到 UILabel
let label = titleStyle(UILabel())
```

#### 实际应用 3：Combine / RxSwift 中的柯里化思想

```swift
import Combine

// 柯里化风格的网络请求
struct APIRequest {
    let baseURL = "https://api.example.com"

    // 柯里化：先配置端点，再指定方法，最后发送
    func endpoint(_ path: String) -> (HTTPMethod) -> (AnyPublisher<Data, Error>) {
        return { method in
            return {
                var request = URLRequest(url: URL(string: "\(self.baseURL)\(path)")!)
                request.httpMethod = method.rawValue
                return URLSession.shared.dataTaskPublisher(for: request)
                    .map(\.data)
                    .mapError { $0 as Error }
                    .eraseToAnyPublisher()
            }
        }
    }
}

enum HTTPMethod: String {
    case GET, POST, PUT, DELETE
}

let api = APIRequest()
let getUsers = api.endpoint("/users")(.GET)  // 固定端点和方式
let getProducts = api.endpoint("/products")(.GET)

// 调用
getUsers().sink(receiveCompletion: { _ in }, receiveValue: { data in
    // 处理用户数据
}).store(in: &cancellables)
```

#### 实际应用 4：数据验证管道

```swift
// 柯里化实现验证器链
typealias Validator<T> = (@escaping (T) -> Bool) -> (T) -> Bool

func notEmpty(next: @escaping (String) -> Bool) -> (String) -> Bool {
    return { value in
        guard !value.trimmingCharacters(in: .whitespaces).isEmpty else {
            print("验证失败：不能为空")
            return false
        }
        return next(value)
    }
}

func minLength(_ length: Int, next: @escaping (String) -> Bool) -> (String) -> Bool {
    return { value in
        guard value.count >= length else {
            print("验证失败：最少 \(length) 个字符")
            return false
        }
        return next(value)
    }
}

func containsUppercase(next: @escaping (String) -> Bool) -> (String) -> Bool {
    return { value in
        guard value.contains(where: { $0.isUppercase }) else {
            print("验证失败：需要包含大写字母")
            return false
        }
        return next(value)
    }
}

// 组合验证规则
let passwordValidator = notEmpty(next:
    minLength(8, next:
        containsUppercase(next: { _ in true })
    )
)

// 使用
passwordValidator("Hello123")  // ✅ 通过
passwordValidator("hello")     // ❌ 验证失败：最少 8 个字符
```

---

## 二、多线程

### 5. iOS 中有哪些实现多线程的方式？各自的特点？

| 方式 | 抽象层级 | 特点 | 适用场景 |
|------|---------|------|---------|
| `pthread` | C 语言 | 最底层，手动管理线程 | 跨平台库 |
| `NSThread` | OC 面向对象 | 轻量，需手动管理生命周期 | 简单线程 |
| **GCD** | C 语言（block） | 自动线程池管理，最常用 | 大多数并发场景 |
| **NSOperationQueue** | OC 面向对象 | 支持依赖、取消、优先级 | 复杂任务编排 |
| **Swift Concurrency** | Swift 原生 | async/await、结构化并发 | 现代 Swift 项目 |

### 6. GCD 中有哪些队列类型？

```
串行队列（Serial Queue）
  └── 主队列（Main Queue）：UI 操作
  └── 自定义串行队列

并发队列（Concurrent Queue）
  ├── 全局并发队列（Global Queue）：
  │   ├── .userInteractive（最高优先级）
  │   ├── .userInitiated
  │   ├── .default
  │   ├── .utility
  │   └── .background（最低优先级）
  └── 自定义并发队列
```

### 7. GCD 死锁的场景有哪些？

```swift
// 场景 1：主队列同步提交 → 死锁
DispatchQueue.main.sync {  // ❌ 主线程等待自己
    print("永远不会执行")
}

// 场景 2：串行队列嵌套同步
let queue = DispatchQueue(label: "serial")
queue.async {
    queue.sync { // ❌ 串行队列中同步提交到自己
        print("死锁")
    }
}
```

**解决方案**：
- 主线程避免 `sync`
- 串行队列嵌套时用 `async` 或用并发队列
- 使用 `DispatchQueue.global()` 避免

### 8. Swift Concurrency（async/await）对比 GCD 有什么优势？

| 维度 | GCD | Swift Concurrency |
|------|-----|-------------------|
| 语法 | 回调/block | async/await 同步写法 |
| 错误处理 | 嵌套 NSError | try/catch 统一 |
| 线程安全问题 | 手动处理 | Actor 自动隔离 |
| 任务取消 | 手动标记 | Task.isCancelled 自动 |
| 任务组 | dispatch_group | TaskGroup |
| 结构化并发 | ❌ 不支持 | ✅ 原生支持 |

```swift
// GCD 版本
func fetchData(completion: @escaping (Result<Data, Error>) -> Void) {
    DispatchQueue.global().async {
        // ... 回调嵌套
    }
}

// Swift Concurrency 版本
func fetchData() async throws -> Data {
    let (data, _) = try await URLSession.shared.data(from: url)
    return data
}
```

---

## 三、锁的用法

### 9. iOS 中有哪些锁？各自的性能和应用场景？

| 锁 | 性能（约） | 特点 | 适用场景 |
|---|----------|------|---------|
| `os_unfair_lock` | ~30ns | 最快，不可递归 | 轻量级互斥 |
| `dispatch_semaphore` | ~50ns | 可控制并发数 | 信号量控制 |
| `pthread_mutex` | ~60ns | 标准互斥锁 | 跨平台 |
| `NSLock` | ~100ns | OC 封装，易用 | 简单互斥 |
| `NSConditionLock` | ~150ns | 条件锁 | 生产者-消费者 |
| `@synchronized` | ~500ns | 最慢，OC 语法糖 | 快速加锁，不追求性能 |
| `os_unfair_recursive_lock` | ~40ns | 可递归 | 递归调用场景 |

```swift
// os_unfair_lock（推荐）
var lock = os_unfair_lock()
os_unfair_lock_lock(&lock)
// 临界区
os_unfair_lock_unlock(&lock)

// dispatch_semaphore（控制并发数）
let sem = DispatchSemaphore(value: 3)
for i in 0..<10 {
    DispatchQueue.global().async {
        sem.wait()
        // 最多 3 个并发
        sem.signal()
    }
}
```

### 10. 什么是读写锁？iOS 中如何实现？

读写锁允许多个读者同时访问，但写者独占。

```swift
// 方式一：dispatch_barrier_async（推荐）
let queue = DispatchQueue(label: "concurrent", attributes: .concurrent)

func read(key: String) -> Any? {
    queue.sync { return cache[key] }  // 并发读
}

func write(key: String, value: Any) {
    queue.async(flags: .barrier) {     // 写时独占
        cache[key] = value
    }
}

// 方式二：pthread_rwlock
var rwlock = pthread_rwlock_t()
pthread_rwlock_rdlock(&rwlock)   // 读锁
pthread_rwlock_wrlock(&rwlock)   // 写锁
pthread_rwlock_unlock(&rwlock)
```

### 11. atomic 关键字能保证线程安全吗？

**不能完全保证**。`atomic` 只保证属性的**读写原子性**（getter/setter 线程安全），但不保证**业务逻辑的线程安全**。

```objc
@property (atomic, strong) NSMutableArray *array;

// ❌ 以下操作不是原子的，即使 array 是 atomic
[self.array addObject:@"new"];  // 1. read array 2. addObject 3. assign
// 其他线程可能在步骤 1 和 3 之间修改了 array

// ✅ 正确的做法：加锁
@synchronized(self) {
    [self.array addObject:@"new"];
}
```

---

## 四、内存管理

### 12. ARC 的工作原理是什么？

ARC（Automatic Reference Counting）在编译期自动插入 retain/release 代码。

```
引用计数变化规则：
  创建对象         → retainCount = 1
  被强引用         → retainCount += 1
  强引用断开       → retainCount -= 1
  retainCount = 0 → dealloc
```

**关键规则**：
- 强引用（strong）：增加引用计数
- 弱引用（weak）：不增加引用计数，对象释放后自动置 nil
- 无主引用（unowned）：不增加引用计数，对象释放后不会置 nil（不安全）

### 13. 循环引用的场景有哪些？如何解决？

| 场景 | 示例 | 解决方案 |
|------|------|---------|
| **Delegate** | `@property (strong) delegate` | 用 `weak` |
| **Block** | block 内直接使用 self | `[weak self]` |
| **NSTimer** | timer target 强引用 self | iOS 10+ 用 block Timer |
| **大对象相互持有** | A → B → A | 一端用 weak |
| **第三方库回调** | 回调持有 self | 检查文档或用 weak |

```swift
// Block 循环引用
class ViewModel {
    var onUpdate: (() -> Void)?

    func setup() {
        onUpdate = { [weak self] in      // ✅ 避免循环引用
            self?.refreshUI()
        }
    }
}

// NSTimer 循环引用
// ✅ iOS 10+
Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
    self?.doSomething()
}
```

### 14. 什么是内存泄漏？如何检测？

**定义**：已经不需要的对象仍被强引用持有，无法被释放。

**检测工具**：
- **Xcode Memory Debugger**：查看对象引用链
- **Instruments Leaks**：实时检测泄漏
- **MLeaksFinder**：第三方泄漏检测库
- **Debug Memory Graph**：查看所有存活对象

**常见泄漏**：
- 循环引用
- 未释放的 NSTimer
- CGGraphics / CF 类型未 release
- 通知未移除
- KVO 未移除

---

## 五、Flutter 混合开发

### 15. Flutter 混合开发的方案有哪些？各自的优缺点？

| 方案 | 原理 | 优点 | 缺点 |
|------|------|------|------|
| **FlutterBoost** | 单引擎 + 原生容器 | 内存小，页面切换流畅 | 集成复杂，版本兼容 |
| **FlutterEngineGroup** | 多引擎（官方） | 每个页面独立 | 内存大，启动慢 |
| **PlatformView** | 原生 View 嵌入 Flutter | 复用原生组件 | 性能差 |
| **FlutterFragment/ViewController** | Flutter 页面嵌入原生 | 简单直接 | 路由管理需手动 |

### 16. Flutter 与原生通信的方式有哪些？

```dart
// 1. MethodChannel（方法调用，最常用）
final channel = MethodChannel('com.app/channel');
final result = await channel.invokeMethod('getData');

// 2. BasicMessageChannel（消息传递）
final msgChannel = BasicMessageChannel('com.app/msg', StringCodec());
msgChannel.send('Hello');

// 3. EventChannel（事件流）
final eventChannel = EventChannel('com.app/events');
eventChannel.receiveBroadcastStream().listen((event) {
    print(event);
});
```

### 17. Flutter 混合开发中如何管理内存？

- **引擎复用**：避免创建多个 FlutterEngine
- **页面销毁**：退出 Flutter 页面时及时释放
- **图片缓存**：控制 Flutter 端图片缓存大小
- **Channel 通道**：不需要时取消监听

---

## 六、从 0 到 1 搭建项目（架构思路）

### 18. 如果让你从零搭建一个 iOS 项目，你会怎么做？

**分层架构**：

```
App Layer（UI 层）
├── Views / ViewControllers / SwiftUI Views
├── Coordinators / Routers（导航）
│
Business Layer（业务层）
├── ViewModels / Presenters
├── UseCases / Interactors
│
Service Layer（服务层）
├── NetworkService（网络）
├── DatabaseService（数据库）
├── CacheService（缓存）
├── LogService（日志）
│
Foundation Layer（基础层）
├── Extensions
├── Utils
├── Third-party Wrappers
├── Constant / Config
```

**关键决策**：

| 决策项 | 推荐方案 | 备选方案 |
|--------|---------|---------|
| 架构模式 | MVVM + Coordinator | VIPER / TCA |
| 网络层 | Moya / Alamofire | URLSession |
| 数据库 | CoreData / Realm | SQLite / GRDB |
| 依赖注入 | Swinject | 手动 DI |
| 响应式 | Combine | RxSwift |
| 路由 | Coordinator Pattern | Router |
| 日志 | CocoaLumberjack | SwiftyBeaver |
| 包管理 | SPM | CocoaPods |

### 19. 项目中如何做依赖注入？

```swift
// 方式一：构造器注入（推荐）
class LoginViewModel {
    let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol) {
        self.networkService = networkService
    }
}

// 方式二：Swinject（第三方 DI 容器）
let container = Container()
container.register(NetworkServiceProtocol.self) { _ in
    NetworkService()
}
container.register(LoginViewModel.self) { r in
    LoginViewModel(networkService: r.resolve(NetworkServiceProtocol.self)!)
}
```

---

## 七、业务模块重构

### 20. 业务模块重构的流程是什么？

**重构流程**：

```
分析现状 → 确定目标 → 设计方案 → 分步实施 → 验证效果 → 持续迭代
```

**具体步骤**：

| 步骤 | 内容 |
|------|------|
| **① 现状分析** | 代码复杂度度量、依赖关系图、测试覆盖度 |
| **② 目标定义** | 可测试性、可维护性、性能指标 |
| **③ 方案设计** | 模块拆分、接口定义、数据流设计 |
| **④ 分步实施** | 按模块逐步替换，小步提交 |
| **⑤ 验证效果** | 测试覆盖、性能对比、Crash 率 |
| **⑥ 持续迭代** | Code Review、技术债务追踪 |

**重构原则**：
- 每次只改一个模块（**Strangler Pattern**）
- 先写测试再重构
- 保持对外接口不变
- 小步提交，频繁集成

---

## 八、性能监控

### 21. iOS 性能监控需要关注哪些指标？

| 指标 | 监控工具 | 阈值 |
|------|---------|------|
| **FPS（帧率）** | CADisplayLink | ≥ 55fps |
| **CPU 使用率** | host_statistics | ≤ 80% |
| **内存占用** | task_info | ≤ 200MB |
| **启动时间** | processInfo.systemUptime | ≤ 2s（冷启动） |
| **网络请求耗时** | NSURLSession 监控 | 按接口定 |
| **页面加载时间** | 自定义打点 | ≤ 500ms |
| **Crash 率** | Crashlytics / Bugly | ≤ 0.1% |
| **卡顿率** | RunLoop 监控 | ≤ 1% |

### 22. 如何监控 FPS 和卡顿？

```swift
// FPS 监控
final class FPSMonitor {
    private var displayLink: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private var count = 0

    func start() {
        displayLink = CADisplayLink(target: self, selector: #selector(tick))
        displayLink?.add(to: .main, forMode: .common)
    }

    @objc private func tick() {
        count += 1
        let interval = displayLink?.timestamp ?? 0
        if interval - lastTimestamp >= 1.0 {
            let fps = count
            print("FPS: \(fps)")
            count = 0
            lastTimestamp = interval
        }
    }
}

// 卡顿监控（RunLoop 观察者）
class LagMonitor {
    private let observer = CFRunLoopObserverCreateWithHandler(
        kCFAllocatorDefault,
        CFRunLoopActivity.allActivities.rawValue,
        true, 0
    ) { observer, activity in
        if activity == .beforeSources || activity == .afterWaiting {
            // 记录时间，超过阈值则表示卡顿
        }
    }
}
```

---

## 九、底层原理

### 23. iOS Runtime 是什么？有哪些实际应用场景？

**Runtime** 是 Objective-C 的**运行时系统**，提供动态能力：

| 应用场景 | 实现方式 | 示例 |
|---------|---------|------|
| **消息转发** | `forwardInvocation:` | 热修复、AOP |
| **方法交换** | `method_exchangeImplementations` | 埋点统计 |
| **动态添加方法** | `class_addMethod` | 动态响应 |
| **关联对象** | `objc_setAssociatedObject` | 分类添加属性 |
| **KVO 实现** | `isa-swizzling` | 属性监听 |
| **字典转模型** | `class_copyIvarList` | YYModel / MJExtension |

### 24. iOS RunLoop 是什么？有哪些 Mode？

RunLoop 是 iOS 的事件循环机制，保持线程不退出，等待事件处理。

```
RunLoop 一次循环：
  ① 处理 Timer 事件
  ② 处理 Source0（非端口事件）
  ③ 处理 Source1（端口事件）
  ④ 进入休眠（等待新事件）
```

**RunLoop Mode**：

| Mode | 说明 | 用途 |
|------|------|------|
| **Default** | 默认模式 | 普通 UI 操作 |
| **Tracking** | 滚动模式 | ScrollView 滚动时 |
| **Common** | CommonModes 集合 | 包含 Default + Tracking |
| **Initialization** | 启动模式 | App 启动时 |

### 25. iOS 中图片从解码到显示到屏幕经历了什么？

完整的图片显示流程：

```
① 图片数据（JPEG/PNG）→ 子线程解码为 Bitmap
② UIImageView.image = image → layer.contents = CGImageRef
③ RunLoop BeforeWaiting → CATransaction commit
④ → Layer Tree → Render Tree（App 进程）
⑤ → XPC → Render Server（backboardd 进程）
⑥ → OpenGL/Metal 指令 → GPU 渲染管线
⑦ → Framebuffer → Vsync → 屏幕显示
```

---

## 十、组件化

### 26. 组件化的目的是什么？如何实现？

**目的**：
- 代码复用，减少重复开发
- 模块解耦，独立开发测试
- 编译加速，增量编译
- 团队分工明确

**实现方案**：

```
App Main（壳工程）
├── Business Component A（业务组件 A）
├── Business Component B（业务组件 B）
├── Middleware Layer（中间件层）
│   ├── Router（路由组件）
│   └── Service Locator（服务定位）
└── Foundation Component（基础组件层）
    ├── Network
    ├── Database
    ├── UIComponent
    └── Utils
```

**组件通信方式**：

| 方式 | 库 | 特点 |
|------|-----|------|
| **URL Router** | MGJRouter / JLRoutes | 通过 URL 跳转 |
| **Target-Action** | CTMediator | 利用 Runtime 解耦 |
| **Protocol-Class** | BeeHive | 注册协议和实现类 |

### 27. CTMediator 组件化方案的原理是什么？

```objc
// 1. Target 定义
@interface Target_A : NSObject
- (UIViewController *)Action_view:(NSDictionary *)params;
@end

// 2. CTMediator 调用
CTMediator *mediator = [[CTMediator alloc] init];
UIViewController *vc = [mediator performTarget:@"A"
                                        action:@"view"
                                        params:@{@"key": @"value"}];
```

**原理**：通过 Runtime 的 `performSelector:withObject:` 动态调用 Target 的 Action 方法，实现完全解耦。

---

## 十一、性能优化

### 28. iOS App 启动优化有哪些手段？

```
App 启动阶段：
pre-main（加载动态库、Rebase、Bind、ObjC Setup、Initializer）
  → main() → didFinishLaunching → 首页渲染完成
```

| 阶段 | 优化手段 | 效果 |
|------|---------|------|
| **pre-main** | 减少动态库数量、合并静态库、缩减 ObjC 类数量 | 减少加载时间 |
| **didFinishLaunching** | 懒加载 SDK、延迟非必须初始化 | 减少启动耗时 |
| **首页渲染** | 预创建、异步加载、骨架屏 | 减少白屏时间 |

### 29. 列表（UITableView/UICollectionView）性能优化有哪些？

| 优化点 | 方案 |
|--------|------|
| **Cell 复用** | registerClass + dequeueReusableCell |
| **高度缓存** | 预计算高度，避免重复计算 |
| **异步渲染** | 子线程绘制文本和图片 |
| **图片降采样** | ImageIO 缩略图解码，避免大图全量解码 |
| **离屏渲染** | 避免 cornerRadius + masksToBounds |
| **减少视图层级** | 扁平化 Cell 视图结构 |
| **数据源优化** | 差分更新（diff）替代 reloadData |

```swift
// 图片降采样
func downsampleImage(at url: URL, to size: CGSize) -> UIImage? {
    let options = [
        kCGImageSourceThumbnailMaxPixelSize: max(size.width, size.height) * UIScreen.main.scale,
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceShouldCacheImmediately: false
    ] as CFDictionary
    let source = CGImageSourceCreateWithURL(url as CFURL, nil)!
    return CGImageSourceCreateThumbnailAtIndex(source, 0, options).map {
        UIImage(cgImage: $0)
    }
}
```

### 30. 如何优化 App 的内存和电量消耗？

| 维度 | 优化措施 |
|------|---------|
| **内存** | 大图降采样、NSCache 自动回收、懒加载、内存警告处理 |
| **电量** | 合并网络请求、降低定位频率、避免后台频繁唤醒 |
| **CPU** | 子线程解码、避免重复计算、使用轻量级数据结构 |
| **网络** | 压缩传输、缓存策略、断点续传 |

---

## 十二、算法与数据结构

### 31. iOS 开发中常用的数据结构和算法有哪些？

| 数据结构 | 应用场景 |
|---------|---------|
| **字典（NSDictionary）** | 缓存 Key-Value 数据 |
| **数组（NSArray）** | 列表数据 |
| **集合（NSSet）** | 去重、成员检测 |
| **栈（Stack）** | 页面导航栈 |
| **队列（Queue）** | 任务调度 |
| **哈希表** | 缓存加速 |

| 算法 | 应用场景 |
|------|---------|
| **排序** | 列表排序、数据整理 |
| **二分查找** | 有序数组查找 |
| **深度/广度优先** | 视图层级遍历 |
| **LRU 淘汰** | 缓存策略 |
| **Diff 算法** | 列表增量更新 |

---

## 十三、数据库

### 32. iOS 中 SQLite 的使用方式有哪些？

| 方式 | 封装程度 | 推荐度 |
|------|---------|--------|
| **FMDB** | OC 轻量封装 | ⭐⭐⭐⭐ |
| **WCDB** | 微信开源，ORM + 加密 | ⭐⭐⭐⭐⭐ |
| **GRDB** | Swift 原生，SQLite 封装 | ⭐⭐⭐⭐ |
| **CoreData** | Apple 官方 ORM | ⭐⭐⭐（学习成本高） |
| **Raw SQLite C API** | 最底层 | ⭐⭐ |

### 33. SQLite 如何做数据库迁移？

```swift
// FMDB 迁移示例
let db = FMDatabase(path: path)
let version = db.userVersion

if version < 1 {
    db.executeUpdate("CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, name TEXT)", nil)
    db.userVersion = 1
}

if version < 2 {
    db.executeUpdate("ALTER TABLE users ADD COLUMN age INTEGER", nil)
    db.userVersion = 2
}
```

---

## 十四、网络

### 34. NSURLSession 的核心组件有哪些？

```
NSURLSessionConfiguration
  ├── .default（默认，支持磁盘缓存）
  ├── .ephemeral（临时，不持久化缓存）
  └── .background（后台下载/上传）

NSURLSession
  └── NSURLSessionTask（抽象）
      ├── NSURLSessionDataTask（GET/POST 请求）
      ├── NSURLSessionUploadTask（上传）
      └── NSURLSessionDownloadTask（下载）
```

### 35. HTTPS 的 SSL Pinning 如何实现？

```swift
// 证书绑定（防中间人攻击）
class PinnedURLSessionDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            return completionHandler(.cancelAuthenticationChallenge, nil)
        }

        // 比较本地证书和服务器证书
        let localCertData = NSData(contentsOf: Bundle.main.url(forResource: "server", withExtension: "cer")!)!
        let serverCert = SecTrustCopyCertificateChain(serverTrust) as! [SecCertificate]
        let serverCertData = SecCertificateCopyData(serverCert[0]) as NSData

        if localCertData == serverCertData {
            completionHandler(.useCredential, URLCredential(trust: serverTrust))
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}
```

---

## 十五、技术规范与文档

### 36. 你如何保证代码规范和质量？

- **SwiftLint**：自动化代码规范检查
- **Code Review**：每个 PR 必须 Review
- **单元测试**：核心逻辑覆盖
- **UI 测试**：关键流程覆盖
- **文档**：README、API doc、架构文档
- **CI/CD**：自动构建、测试、部署

---

## 十六、英语面试问题

### 37. Please introduce yourself and your most complex iOS project.

```english
I have 3+ years of iOS development experience. My most complex project was a health tracking app
for women, which included features like cycle tracking, AI-powered predictions, and community features.
I was responsible for the architecture design from scratch, using MVVM + Coordinator pattern.
I also integrated Flutter modules for the community feature using FlutterBoost.
The app serves millions of users and has a crash rate below 0.1%.
```

### 38. How do you handle communication with a US-based team?

- Daily standup meetings via Slack/Zoom
- Clear documentation in English
- JIRA for task tracking
- Code comments and PR descriptions in English
- Adapt to time zone differences

---

## 十七、AI 工具

### 39. 你在日常开发中使用哪些 AI 工具？

| 工具 | 用途 |
|------|------|
| **GitHub Copilot** | 代码补全、单元测试生成 |
| **ChatGPT / Claude** | 技术方案讨论、调试帮助 |
| **AI 代码审查** | 自动 Review |
| **AI 测试生成** | 自动生成 XCTest |
| **AI 翻译** | 本地化字符串处理 |

---

## 十八、开放源码

### 40. 你有自己的开源项目吗？可以介绍一下。

（面试者根据实际情况回答，重点说明解决的问题、技术栈、Star 数、PR 情况）

**开源项目的价值**：
- 展示代码质量和架构能力
- 体现学习能力和社区贡献
- 证明对技术的热情
