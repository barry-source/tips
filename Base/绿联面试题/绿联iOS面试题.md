# 绿联科技 iOS 开发面试题

来源：绿联科技 iOS 开发工程师岗位要求 + CSDN 面试指南

---

## 岗位要求概览

绿联科技 iOS 开发岗位要求：

| 技术领域 | 具体要求 |
|---------|---------|
| **Swift/SwiftUI** | 精通 Swift，熟悉 SwiftUI，有实际项目经验 |
| **Objective-C** | 精通 OC，能维护遗留代码 |
| **Flutter** | 熟悉 Flutter + Dart，有跨平台项目经验 |
| **网络** | TCP/IP、UDP、HTTP、Socket 通信 |
| **蓝牙** | BLE 设备交互（岗位2） |
| **流媒体** | RTMP/HLS、音视频编解码、IPC Camera（岗位2） |
| **架构** | MVVM / VIPER，良好的架构设计能力 |
| **其他** | 独立上架经验、产品意识、IoT/AI 经验优先 |

---

## 面试题

### 1. 请描述你使用 SwiftUI 开发的经验，包括一个实际项目案例

SwiftUI 是 Apple 的声明式 UI 框架。在最近的项目中，我使用 SwiftUI 构建了电商应用的主界面，采用 MVVM 架构：

```swift
struct ProductListView: View {
    @ObservedObject var viewModel: ProductViewModel

    var body: some View {
        List(viewModel.products) { product in
            Text(product.name)
        }
    }
}
```

挑战包括处理异步数据加载，使用 Combine 框架管理状态。优化方面，使用 `LazyVStack` 提升滚动性能。项目成功上架 App Store。

---

### 2. 如何优化 iOS 应用的网络性能？请结合 TCP/IP 协议解释

优化需多层面处理：
- **TCP/IP 层面**：TCP 确保可靠传输，但拥塞控制可能降低效率。调整超时和缓存策略
- **URLSession 配置**：

```swift
let config = URLSessionConfiguration.default
config.timeoutIntervalForRequest = 30
config.requestCachePolicy = .returnCacheDataElseLoad
```

- **减少请求次数**：合并 API 调用，使用 GraphQL
- **监控**：用 Charles 分析网络流量
- **缓存**：合理使用 `URLCache`，减少重复请求

---

### 3. 请说明 Flutter 在跨平台开发中的优势，并分享一个项目经验

Flutter 优势：
- **高性能渲染**：通过 Skia 自绘引擎，不依赖平台 UI 组件
- **热重载**：修改代码秒级生效
- **一套代码**：iOS 和 Android 共享代码库

在物流 App 项目中，我使用 Flutter 实现了地图组件：

```dart
class MapScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(target: LatLng(37.4, -122)),
    );
  }
}
```

挑战：处理平台特定功能，通过 `MethodChannel` 调用 iOS 原生定位 API。项目节省 30% 开发时间，性能接近原生。

---

### 4. BLE 设备交互中，如何处理数据分包和错误恢复？

BLE 数据传输可能分包发送，使用 CoreBluetooth 处理：

```swift
func peripheral(_ peripheral: CBPeripheral,
                didUpdateValueFor characteristic: CBCharacteristic,
                error: Error?) {
    if let data = characteristic.value {
        // 拼接数据包
    }
    if error != nil {
        // 重试逻辑：指数退避算法
    }
}
```

错误恢复策略：
- **ACK 机制**：设备确认接收数据
- **超时重连**：超时 5 秒自动重连
- **数据校验**：使用 CRC 校验数据完整性

---

### 5. 请描述你使用流媒体传输协议的经验，如 RTMP 或 HLS

在视频会议 App 中，我使用 HLS 协议传输流媒体。HLS 将视频切片为 TS 文件，通过 HTTP 分发。iOS 端使用 AVPlayer 播放：

```swift
let url = URL(string: "https://example.com/stream.m3u8")!
let player = AVPlayer(url: url)
player.play()
```

优化策略：
- **自适应码率切换**：根据网络状况动态切换分辨率
- **编解码**：H.264 编解码，软硬件结合
- **延迟控制**：优化缓冲区大小，目标延迟低于 2 秒

---

### 6. 如何设计一个可扩展的 iOS 应用架构？请举例说明

采用分层设计架构：
- **表现层（UI）**：SwiftUI / UIKit 视图
- **业务逻辑层**：Interactor / ViewModel
- **服务层**：网络、数据库、蓝牙等基础服务

在社交 App 项目中，我使用 VIPER 模式：

```swift
class UserInteractor {
    func fetchUser(id: Int) -> User { /* 业务逻辑 */ }
}
```

原则：
- **依赖注入**：确保模块解耦
- **单一职责**：每个模块只做一件事
- **测试覆盖**：单元测试覆盖率达 80% 以上

---

### 7. 在 Swift 中，如何处理内存管理和避免循环引用？

Swift 使用 ARC 管理内存。避免循环引用：

```swift
// delegate 用 weak
class ViewController {
    weak var delegate: DelegateProtocol?
}

// 闭包中用 [weak self]
networkService.fetchData { [weak self] data in
    self?.updateUI()
}
```

**检测工具**：Xcode Memory Debugger、Instruments（Leaks）

**常见陷阱**：
- 闭包捕获 self → 用 `[weak self]` 或 `[unowned self]`
- NSTimer 强引用 target → 用 iOS 10+ 的 `block` 版本 Timer
- 代理未置 nil → 用 `weak` 修饰

---

### 8. 请分享你独立开发并上架 iOS 产品的流程和经验

上架流程：
1. **开发**：Swift + SwiftUI / UIKit，CoreData / Realm
2. **测试**：XCTest 单元测试 + TestFlight Beta 测试
3. **提交**：准备元数据（截图、描述、隐私政策）
4. **审核**：处理常见拒绝原因

**经验**：
- 提前配置好隐私权限描述（Info.plist）
- 模拟审核流程，用 App Store Connect 跟踪状态
- 上线前检查：64位支持、iPad 适配、崩溃率

---

### 9. 如何确保代码品质？请谈谈你的代码评审实践

- **Code Review**：团队每周 PR 评审，关注 SOLID 原则、可读性、测试覆盖
- **工具**：SwiftLint 自动检查代码规范、Jenkins CI 集成
- **自文档化代码**：清晰的命名和注释

评审关注点：
```
✅ 命名规范（camelCase）
✅ 单一职责
✅ 测试覆盖
✅ 无硬编码
❌ 过度设计
❌ 魔法数字
```

---

### 10. 对于 IPC Camera 开发，请描述音视频编解码的优化方法

IPC Camera 涉及 H.264 编码优化：

1. **硬件加速**：使用 VideoToolbox 框架进行硬编解码
2. **码率控制**：根据网络状况动态调整码率
3. **预处理**：降噪和分辨率缩放

```swift
// VideoToolbox 硬解码
import VideoToolbox

func decodeFrame(data: CMSampleBuffer) {
    // VideoToolbox 自动利用硬件加速
}
```

压缩目标：压缩比达到 50:1。

---

### 11. 在 Flutter 中，如何实现原生功能调用？

通过 **Platform Channels** 实现：

```dart
// Flutter 端
final methodChannel = MethodChannel('camera');
Future<void> takePhoto() async {
    try {
        await methodChannel.invokeMethod('takePhoto');
    } catch (e) {
        print(e);
    }
}
```

```swift
// iOS 原生端
public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "takePhoto" {
        // 相机逻辑
        result(nil)
    }
}
```

---

### 12. 请解释 HTTP 和 HTTPS 的区别，以及在 iOS 中的实现

| 维度 | HTTP | HTTPS |
|------|------|-------|
| **加密** | 明文传输 | TLS/SSL 加密 |
| **端口** | 80 | 443 |
| **安全性** | 低，可被中间人攻击 | 高，证书验证 |
| **性能** | 快 | 稍慢（加密开销） |

iOS 中 URLSession 自动处理 HTTPS：

```swift
// ATS 配置（Info.plist）
// 推荐使用合法证书，不关闭 ATS
let url = URL(string: "https://api.example.com")!
let task = URLSession.shared.dataTask(with: url)
```

---

### 13. 如何调试 iOS 应用的性能问题？

工具：**Xcode Instruments**

| Instrument | 用途 |
|-----------|------|
| **Time Profiler** | CPU 耗时分析 |
| **Allocations** | 内存分配跟踪 |
| **Leaks** | 内存泄漏检测 |
| **Core Animation** | 离屏渲染、帧率 |

**优化步骤**：
1. 识别瓶颈（CPU / 内存 / GPU）
2. 针对优化（减少离屏渲染、重用 Cell、图片降采样）
3. 测试验证（不同设备、不同 iOS 版本）

---

### 14. 对于 SwiftUI 的状态管理，请比较 @State、@ObservedObject 和 @EnvironmentObject

| 属性包装器 | 类型 | 作用域 | 用途 |
|-----------|------|--------|------|
| `@State` | 值类型 | 视图内部 | 简单的本地状态 |
| `@StateObject` | 引用类型 | 视图自有 | 创建和管理 ObservableObject |
| `@ObservedObject` | 引用类型 | 外部传入 | 从父视图传入的可观察对象 |
| `@EnvironmentObject` | 引用类型 | 全局共享 | 跨视图层级共享数据 |

```swift
struct MyView: View {
    @State private var count = 0               // 本地状态
    @ObservedObject var user: User             // 外部传入
    @EnvironmentObject var settings: Settings  // 全局共享

    var body: some View {
        Text("Count: \(count)")
    }
}
```

---

### 15. 在蓝牙项目中，如何处理多设备连接？

CoreBluetooth 支持多设备连接：

```swift
var connectedPeripherals: [CBPeripheral] = []

func connectPeripheral(_ peripheral: CBPeripheral) {
    centralManager.connect(peripheral)
    connectedPeripherals.append(peripheral)
}
```

处理策略：
- **UUID 标识**：用设备 UUID 区分
- **连接队列**：维护连接池，限制最大连接数
- **超时断开**：空闲设备自动断开
- **重连机制**：断线后自动重连（指数退避）

---

### 16. 请谈谈你对产品意识的理解，并举例说明如何驱动工作

产品意识指**以用户需求和业务效果为导向**。

在新闻 App 项目中：
- 用户反馈的痛点是加载速度慢
- 我优先优化了图片缓存和网络请求策略
- 结果：用户留存率提升 20%

**驱动方法**：
- 定期分析用户数据（Firebase Analytics）
- 关注 Crash 率和用户反馈
- 技术选型时优先考虑用户体验

---

### 17. 如何实现 iOS 应用的安全防护？

| 安全层面 | 措施 |
|---------|------|
| **数据加密** | CryptoKit / CommonCrypto |
| **网络** | HTTPS + 证书绑定（SSL Pinning） |
| **本地存储** | Keychain 保护敏感数据 |
| **反调试** | 检测调试器附加 |
| **代码混淆** | 混淆关键字符串和逻辑 |

```swift
// 证书绑定示例
let pinnedKeys = ["<public-key-hash>"]
func urlSession(_ session: URLSession,
                didReceive challenge: URLAuthenticationChallenge,
                completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
    // 验证服务器证书
}
```

---

### 18. 在跨平台开发中，Flutter 与 React Native 的比较

| 维度 | Flutter | React Native |
|------|---------|-------------|
| **渲染引擎** | Skia 自绘引擎 | 原生组件桥接 |
| **性能** | 高，接近原生 | 中，桥接有开销 |
| **热重载** | ✅ 秒级 | ✅ 秒级 |
| **语言** | Dart | JavaScript |
| **UI 一致性** | 跨平台一致 | 依赖原生，有差异 |
| **生态** | 相对年轻 | 相对成熟 |

**选择建议**：
- Flutter：UI 复杂度高、追求性能一致性的项目
- React Native：已有 Web 团队、需要大量第三方库的项目

---

### 19. 请描述你处理紧急需求的经验

在支付 App 中，接到紧急修复需求：处理支付失败 Bug。

**处理步骤**：
1. **分析**：查看崩溃日志和用户报告，定位到网络重试逻辑问题
2. **修复**：修改网络重试机制，增加超时处理和重试次数限制
3. **测试**：快速回归测试核心支付流程
4. **发布**：用 TestFlight 验证后提交 App Store 审核

**关键**：保持冷静，优先保障核心功能可用。

---

### 20. 对于 AI 应用场景，请分享一个相关开发经验

在健康 App 中，集成 Core ML 实现心率预测：

```swift
func predictHeartRate(data: [Double]) -> Double? {
    let model = HeartRateModel()
    guard let prediction = try? model.prediction(input: data) else { return nil }
    return prediction.output
}
```

**流程**：
1. **训练模型**：用 Python + Create ML 训练模型
2. **集成 iOS**：导入 Core ML 模型文件到 Xcode
3. **推理**：使用 Core ML API 进行预测
4. **优化**：模型量化压缩，确保离线可用
