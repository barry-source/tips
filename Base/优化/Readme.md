# iOS 性能优化

> 涵盖启动、卡顿、渲染、列表、内存、包体积、网络、I/O 和电量等全链路优化，适合高级/资深 iOS 面试。

---

## 一、启动优化

### 1.1 App 启动的三个阶段

```
main() 函数执行前   →   main() 函数执行后   →   首屏渲染完成（didFinishLaunching + 首帧渲染）
```

---

### 1.2 Mach-O 文件结构

理解 Mach-O 文件类型和结构是启动优化的基础。**dyld**（dynamic link editor，动态链接编辑器）加载和解析的正是 Mach-O 文件。dyld 负责在 App 启动时递归加载所有依赖的动态库、进行 Rebase/Binding 符号修正、执行 Objc Runtime 初始化等工作，最终调用 `main()` 函数。

#### 1.2.1 文件类型（file type）

```
┌─────────────┬────────────────────────────────────────────────────┐
│  文件类型     │  说明                                               │
├─────────────┼────────────────────────────────────────────────────┤
│ Executable  │ 应用程序的主要二进制文件，可执行                      │
│ dylib      │ 动态链接库（对应 Linux 平台的 DSO 和 Windows 的 DLL）│
│ Bundle     │ 特殊类型的 dylib，只能在运行时通过 dlopen 打开       │
│            │ 主要用于 macOS 上的插件（如 .bundle 资源包）       │
│ Image      │ 统称 Executable、dylib 或 Bundle 类型              │
│ Framework  │ 一种 dylib，具有特殊的目录结构（Headers/Resources/） │
│            │ 用于持有该 dylib 所需的资源文件和头文件            │
└─────────────┴────────────────────────────────────────────────────┘
```

> 💡 **Image 是最广泛的统称**：在 Mach-O 术语中，Executable、dylib、Bundle 统称为 Image。dyld 加载和处理的每一个文件都是 Image。

#### 1.2.2 Mach-O 文件结构

大多数 Mach-O 二进制文件都包含三个主要 Segment（段）：

```
+------------------------+
│    Mach-O Header       │  ← 文件类型、CPU 类型、架构、指令数等
│  (文件头，元数据)        │
+------------------------+
│  Segment: __TEXT       │  ← 只读段
│  - 代码段（.text）      │  ← 所有机器指令（机器码）
│  - 只读常量区           │  ← 字符串字面量（如 Objective-C 中的 @"xxx"）
│  - Mach header 信息     │  ← 在段内继续细分
+------------------------+
│  Segment: __DATA       │  ← 可读写段
│  - 可读写全局变量       │  ← 全局变量（未初始化在 .bss，已初始化在 .data）
│  - 静态变量             │  ← static 变量
│  - Objc 运行时数据      │  ← 类、方法、Category 等
+------------------------+
│  Segment: __LINKEDIT   │  ← 加载元数据段
│  - 符号表（Symbol Table）│  ← 函数名、变量名等符号
│  - 重定位表             │  ← Rebase/Binding 需要的数据
│  - 动态链接信息         │  ← dyld 需要的加载指令
│  - 字符串表             │  ← 符号名的字符串池
│  - 代码签名             │  ← 签名数据（Code Sign）
+------------------------+
```

| Segment | 属性 | 内容 | 说明 |
|---------|------|------|------|
| **__TEXT** | 只读 | 机器指令、字符串常量、Mach header | 启动时会被映射到内存，标记为只读保护，防止修改 |
| **__DATA** | 读写 | 全局变量、静态变量、Objc 运行时数据（class、category、方法列表等） | 需要在运行时修改，标记为读写 |
| **__LINKEDIT** | 只读 | 符号表、重定位信息、签名数据 | dyld 链接时读取，不需要在运行时写入 |

> ⚠️ **dyld 与 Mach-O 的关系**：
> - `__TEXT` 中存放了所有可执行代码，dyld 先将其映射到内存（ASLR 后虚拟地址）
> - `__DATA` 中的指针需要通过 Rebase 修正（因为 ASLR 地址随机）
> - `__LINKEDIT` 中的符号表用于 Bind 阶段解析外部符号（如 NSLog 的地址来自系统库）
> - 代码签名（Code Sign）也在 `__LINKEDIT` 中，验证时校验每个 page 的 hash

---

### 1.3 main() 执行前优化

**系统做的事情（dyld 主导）：**

```
① 加载 dyld 自身，递归加载所有依赖的动态库（dylib）
② Rebase — 修正内部指针（因为 ASLR 地址随机）
③ Bind — 绑定符号表（查找外部符号的地址）
④ Objc Runtime 初始化：类注册、Category 注册、Selector 唯一性检查
⑤ 执行 +load() 方法、C/C++ 静态全局变量初始化
⑥ 调用 main()


1、加载dyld,并由dyld递归加载依赖的动态链接库dylib
2、进行 rebase 指针调整和 bind 符号表绑定；(fix-up, 为什么有这个操作，因为code signing, fix-up 主要是针对_DATA)
3、Objc 运行时的初始处理，包括 Objc 相关类的注册、category 注册、selector 唯一性检查等；
4、初始化，包括了执行 +load() 方法、attribute((constructor)) 修饰的函数的调用、创建 C++ 静态全局变量
```

**dyld 提供调试手段：**

```bash
# Xcode Scheme → Arguments → Environment Variables
DYLD_PRINT_STATISTICS=1                  # 打印 pre-main 耗时总览
DYLD_PRINT_STATISTICS_DETAILS=1          # 打印每个 dylib 的细节
```

**Main 前优化表：**

| 优化手段 | 详细说明 | 效果参考 |
|---------|---------|---------|
| **减少动态库数量** | Apple 建议非系统动态库 ≤ 6 个；合并自有动态库为静态库 | 每减少 1 个 ≈ 减少 2-5ms |
| **合并同类动态库** | 将多个私有/第三方 Framework 合并为一个 | 减少 page-in 次数，每减少 1 个 dylib 可减少 2-5ms || **使用 -ObjC 优化** | 只在必要时使用 -ObjC，避免加载全部符号 | 减少 bind 阶段耗时 |
| **移除无用类/方法** | 用 `LSUnusedResources` 或 `periphery` 检测 | 减少 objc 初始化量 |
| **+load() → +initialize()** | +load 在 main 前同步执行；+initialize 在首次使用时执行 | 差异可达 10ms+ |
| **减少 C++ 全局变量** | 每个 C++ 全局对象构造函数都会在 main 前执行 | 全局变量多时明显 |
| **减少 Objc 分类** | 每个 Category 会被注册，分类越多注册越慢 | — |
| **使用 Swift** | Swift 没有 +load，类型注册在编译期完成 | 启动速度更优 |
#### 合并同类动态库的实战方案

> 常见场景：项目依赖了多个第三方 Framework（如 AFNetworking.framework、SDWebImage.framework、YYModel.framework 等），每个都是一个独立的 dylib，pre-main 阶段需要逐个加载，造成大量 page-in。

**方案一：CocoaPods 统一转为静态库（推荐）**

```ruby
# Podfile
# 将所有 Pod 统一编译为静态库，不再生成动态 Framework
use_frameworks! :linkage => :static

# ⚠️ 注意：静态链接后所有代码会被打包到主二进制中
# 主二进制只依赖系统动态库（UIKit、Foundation 等），不再有私有动态库
# pre-main 阶段 dyld 不需要加载这些库
```

| 状态 | dylib 数量 | 效果 |
|------|-----------|------|
| 使用前（默认 `use_frameworks!`） | 每个 Pod 1 个 dylib，共 10-30 个 | pre-main 600-1200ms |
| 使用后（`:linkage => :static`） | 仅系统 dylib（约 6-8 个） | pre-main 200-400ms |

> ⚠️ **注意**：部分 Pod 对动态库有硬依赖（如包含 Resource Bundle 或 Extension），需逐个验证。

**方案二：创建聚合动态 Framework（手动合并第三方库）**

```bash
# 第一步：将需要合并的第三方 .framework 和主工程二进制合并
# 创建一个脚本，在 Build Phases → Run Script 中执行

# 示例：合并 AFNetworking.framework + SDWebImage.framework → Aggregated.framework

# 1. 将多个静态库合并为一个统一静态库
# （如果第三方提供的是 .a 文件）
libtool -static -o merged.a \
  Pods/AFNetworking/libAFNetworking.a \
  Pods/SDWebImage/libSDWebImage.a \
  Pods/YYModel/libYYModel.a

# 2. 或者将多个 .framework 中的 .a 提取出来再合并
for framework in AFNetworking SDWebImage YYModel; do
    cp -r "Pods/${framework}.framework" "Aggregated.framework/"
done

# 但更常见的做法是：在 Podfile 中指定部分库为 static
# 以减小主二进制负担
```

**方案三：CocoaPods 混编（部分静态 + 部分动态）**

```ruby
# Podfile — 灵活混编
# 将非必须动态加载的库转为静态库

# 方式 A：全局静态，个别动态
use_frameworks! :linkage => :static
pod 'Alamofire'         # 静态
pod 'RxSwift'           # 静态
pod 'SomeDynamicPod'    # 如果必须动态... 需要手动配置

# 方式 B：指定某些 Pod 不使用 framework（CocoaPods 1.9+）
install! 'cocoapods', :disable_input_output_paths => true

# 方式 C：使用静动态混编插件
plugin 'cocoapods-static-swift'
```

**方案四：SPM（Swift Package Manager）替代 Cocoapods**

```swift
// Package.swift 或 Xcode 直接添加 Package
// SPM 默认将依赖编译为静态库，不会生成额外的动态库
// 除非显式声明 type: .dynamic

// Xcode → File → Add Package Dependencies
// 添加的依赖默认静态链接到主 target
// pre-main 阶段不需要额外加载 dylib
```

**方案五：手动合并 .a 文件（最彻底但维护成本高）**

```bash
# 1. 分别编译各架构版本
xcodebuild -project AFNetworking.xcodeproj -scheme AFNetworking \
  -sdk iphoneos -arch arm64 -configuration Release \
  -derivedDataPath ./build

# 2. 合并多个静态库
libtool -static -o alldata.a \
  build/arm64/libAFNetworking.a \
  build/arm64/libSDWebImage.a

# 3. 如果包含多架构，再用 lipo 合并
lipo -create \
  build/arm64/libAFNetworking.a \
  build/arm64e/libAFNetworking.a \
  -output libAFNetworking.a
```

**方案六：仅编译需要使用的架构**

```bash
# 在 Build Settings 中设置：
# Excluded Architectures → 排除不需要的架构
# 例如 Debug 模式只编译 arm64，不编译 arm64e
# 减少编译产物体积，间接减少 page-in

# 或者使用 Podfile 配置
post_install do |installer|
  installer.pods_project.build_configurations.each do |config|
    config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
  end
end
```

**面试小结：**

| 方案 | 适合场景 | 优缺点 |
|------|---------|--------|
| `:linkage => :static` | CocoaPods 项目 | ✅ 操作简单，❌ 部分 Pod 不兼容 |
| 聚合 Framework | 需保留动态加载特性 | ✅ 减少 dylib 数，❌ 维护脚本复杂 |
| 混编方案 | 大型项目逐步迁移 | ✅ 灵活可控，❌ 配置略复杂 |
| SPM | 新项目或 Swift 项目 | ✅ 默认静态链接，❌ 部分库不支持 |
| 手动合并 .a | 对体积/启动极致追求 | ✅ 最彻底，❌ 运维成本高 |

> **核心原则**：pre-main 阶段的 dylib 加载是串行的（dyld 递归加载），每加载一个 dylib 就需要一次 page-in。将多个私有/第三方动态库合并或转为静态库，是减少 pre-main 耗时最有效的手段之一。

---

#### Binary Reordering（二进制重排 / 秩序文件）

**原理**：App 启动时会触发大量缺页中断（Page Fault），因为代码按编译顺序排列而非按执行顺序。通过 order file 将启动路径上的函数集中排列，减少 Page Fault 次数。

```bash
# 1. 在 Build Settings 写入 order file 路径
.order File = $(SRCROOT)/xxx.order

# 2. 利用 Clang 的 SanitizerCoverage 收集启动时函数调用顺序
# 在 Other C Flags 添加：
-fsanitize-coverage=func,trace-pc-guard

# 3. 启动 App，hook __sanitizer_cov_trace_pc_guard 记录地址
# 4. 解析符号表生成 order 文件，排在前面的函数会被集中排列

# 效果：大型 App （如微信）通过二进制重排可减少 50%+ 的 Page Fault
# Pre-main 时间从 1200ms → 600ms（微信公开数据）
```

**实现示例：**

```objc
// 在 +load 或 AppDelegate 中注册回调
#import <sanitizer/coverage_interface.h>

// 使用 lnk_set 去重，记录启动时触发的所有函数地址
void __sanitizer_cov_trace_pc_guard(uint32_t *guard) {
    // 获取当前 PC 地址
    void *PC = __builtin_return_address(0);
    // 记录到全局集合（用原子操作或锁保证线程安全）
    atomic_fetch_add(&orderFileCount, 1);
    // 符号化后写入文件
    // ...
}

// 最后用 atexit 或通知时机输出符号列表
// 格式：每个符号一行，按执行顺序排列
```

### 1.4 main() 执行后优化

| 优化手段 | 详细说明 |
|---------|---------|
| **SDK 延迟初始化** | 非首屏必须的 SDK 放到首帧渲染完成后初始化（`dispatch_async`） |
| **选择 AppDelegate 精简** | 将 AppDelegate 中的逻辑拆分到各个模块的独立管理器中 |
| **懒加载 Module** | 各业务模块首次使用时才注册/初始化 |
| **子线程预加载** | 数据库初始化、配置文件读取放到子线程 |
| **首帧预渲染** | 提前计算首屏布局，避免在首帧时才计算 |
| **方法结果缓存** | 高频调用的计算结果（如字体、颜色、配置）加缓存 |
| **优化 +load 迁移** | 检查是否有遗漏的 +load 未迁移到懒加载方案 |

- 1、首屏初始化所需配置文件的读写操作；
-  2、首屏列表大数据的读取； 
- 3、首屏渲染的大量计算等 
- 4、各SDK和功能模块的初始化，（延迟加载->子线程加载->主线程加载） 
- 5、加载图片，用 Asset 管理图片而不是直接放在 bundle， Asset 会在编译期做优化，让加载的时候更快 
- 6、高频次方法加缓存（计算高度等放入字典中，注意字典膨胀问题） 
- 7、锁，子线程加锁可能会影响主线程 
- 8、最优线程数量是不超过Cpu核心数

#### Pre-main 测量产出

```
Total pre-main time: 680.72 milliseconds
dylib loading time: 128.78 ms
rebase/binding time:  72.34 ms
ObjC setup time:     412.56 ms   <-- 这里是优化大头
initializer time:     67.04 ms
slowest intializers:
    libWeChatSDK ...  32.52 ms
    libBDMapSDK ...   18.31 ms
```

---

## 二、卡顿优化

### 2.1 卡顿原理

```
60 FPS → 每帧预算 16.67ms
120 FPS → 每帧预算 8.33ms (ProMotion)

CPU（布局/绘制/解码） + GPU（合成/渲染） > 帧预算 → 掉帧 → 卡顿
```

### 2.2 CPU 优化

| 优化点 | 方案 | 原理 |
|--------|------|------|
| **轻量级视图** | 无交互用 CALayer 替代 UIView | CALayer 轻量，没有事件处理 |
| **批量修改属性** | 用 `UIView.animate` 或事务批量修改 frame | 减少布局计算次数 |
| **布局优化** | Frame 布局 > Auto Layout ≈ FlexBox | Auto Layout 方程求解复杂度 O(n³) |
| **图片对齐** | Image size 与 UIImageView size 保持一致 | 避免缩放额外开销 |
| **文本计算** | 子线程预计算 text size、attributedText | 主线程省去排版计算 |
| **图片解码** | 子线程预解码图片（CGContext 绘制） | decode 在主线程会导致卡顿 |
| **并发控制** | GCD 默认全局队列并行数无限制，用信号量控制 | 避免线程爆炸 → 上下文切换开销 |

### 2.3 GPU 优化

| 优化点 | 方案 | 详细 |
|--------|------|------|
| **减少图层混合** | `opaque = YES`，背景色与父视图一致 | 混合需要读取多图层像素做 alpha blend |
| **减少视图层级** | 层级越少，GPU 合成越快 | 每个 layer 都要渲染和合成 |
| **纹理上限** | 单纹理 ≤ 4096x4096 | 超限走 CPU 软件渲染 |
| **合并渲染** | 多张图片合并为一张，减少 draw call | 特别适合列表中的多图场景 |
| **离屏渲染** | 见下节 | — |

### 2.4 离屏渲染详解

#### 2.4.1 渲染分类

iOS 中的渲染按处理方式分为两类：

```
                        iOS 渲染
                            │
          ┌─────────────────┴─────────────────┐
          │                                   │
    CPU 渲染（软件渲染）                 GPU 渲染（硬件渲染）
          │                                   │
    CPU 绘制成 Bitmap，        ┌───────────────┴───────────────┐
    再交给 GPU 显示           │                               │
                          GPU 帧缓冲区渲染           非 GPU 帧缓冲区渲染
                         （直接渲染到屏幕）       （额外开辟缓冲区）
```

| 渲染类型 | 说明 | 是否属于离屏渲染 |
|---------|------|:--------------:|
| **CPU 渲染**（软件渲染） | CPU 通过 Core Graphics 在 Bitmap context 上绘制，生成位图后传递给 GPU 显示 | ✅ **是**（不在 GPU 帧缓冲区中） |
| **GPU 帧缓冲区渲染**（On-Screen） | GPU 直接渲染到当前帧缓冲区（Frame Buffer），直接输出到屏幕 | ❌ |
| **非 GPU 帧缓冲区渲染**（Off-Screen） | GPU 在当前帧缓冲区之外开辟额外的缓冲区进行渲染，完成后切回帧缓冲区 | ✅ **是** |

> **核心定义**：CPU 渲染和非 GPU 帧缓冲区渲染统称为**离屏渲染**。两者的共同点是渲染结果没有直接输出到屏幕的帧缓冲区，而是先写入中间存储（CPU 的 Bitmap context 或 GPU 的额外缓冲区），再传递给帧缓冲区。

**两种离屏渲染的区别：**

| 对比维度 | CPU 渲染 | GPU 非帧缓冲区渲染 |
|---------|---------|------------------|
| 处理单元 | CPU | GPU |
| 缓冲区 | CPU 内存中的 Bitmap context | GPU 额外帧缓冲区 |
| 触发条件 | `drawRect:`、CGBitmapContextCreate | 圆角+clipsToBounds、阴影、mask 等 |
| 是否可异步 | ✅ 可子线程异步绘制 | ❌ 必须在渲染管线中同步执行 |
| 性能影响 | 占用 CPU 时间，但可通过异步缓解 | 占用 GPU 时间，且需要上下文切换 |

#### 2.4.2 渲染路径对比

```
❌ 离屏渲染：
   GPU 当前帧缓冲区 → 额外开辟新的缓冲区 → 渲染 → 切换回帧缓冲区 → 合成

✅ 正常渲染：
   GPU 当前帧缓冲区 → 直接渲染到屏幕
```

| 触发条件 | 代码示例 | 优化方案 |
|---------|---------|---------|
| 圆角 + clipsToBounds | `cornerRadius + masksToBounds` | 用贝塞尔裁剪绘制图片 |
| 阴影 | `layer.shadowColor/Offset/Radius` | 指定 `shadowPath` |
| 遮罩 | `layer.mask` | 用图片替代 mask 层 |
| `allowsGroupOpacity` | `opacity < 1.0` + group opacity | 单独控制子视图透明度 |
| `shouldRasterize` | 开启栅格化缓存 | 只用于内容不变的视图 |
| `drawRect:` | 重写 drawRect 方法 | 用子线程绘制 bitmap |
| 文字渲染 | UILabel / CATextLayer | Core Text 异步绘制 |

**圆角优化终极方案：**

```swift
// ✅ 最推荐的方案：用 UIBezierPath 绘制圆角图片
extension UIImage {
    func withRoundedCorner(_ radius: CGFloat) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { ctx in
            let rect = CGRect(origin: .zero, size: size)
            UIBezierPath(roundedRect: rect, cornerRadius: radius).addClip()
            draw(in: rect)
        }
    }
}

// ✅ 另一种方案：用 mask 但配合 shouldRasterize 缓存
imageView.image = image.withRoundedCorner(10)
imageView.layer.shouldRasterize = true
imageView.layer.rasterizationScale = UIScreen.main.scale

// ⚠️ 注意：不要直接在 cell 上对动态变化的图用 shouldRasterize
// 因为每次图片变化都需要重绘，栅格化缓存失效反而更慢
```

**阴影优化：** 指定 `shadowPath` 后，GPU 不需要计算阴影形状。

```swift
// ❌ 不指定 shadowPath — GPU 需要计算形状
view.layer.shadowOpacity = 0.5
view.layer.shadowOffset = CGSize(width: 0, height: 2)

// ✅ 指定 shadowPath — GPU 直接使用
view.layer.shadowPath = UIBezierPath(rect: view.bounds).cgPath
// 如果 bounds 变化，需要在 layoutSubviews 中更新 shadowPath
```

### 2.5 卡顿监控方案

**方案一：FPS 监控（CADisplayLink）**

```objc
@interface FPSMonitor : UILabel
@property (nonatomic, strong) CADisplayLink *link;
@property (nonatomic, assign) NSUInteger count;
@property (nonatomic, assign) NSTimeInterval lastTime;
@end

@implementation FPSMonitor
- (void)start {
    self.link = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick:)];
    [self.link addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
}

- (void)tick:(CADisplayLink *)link {
    if (self.lastTime == 0) { self.lastTime = link.timestamp; return; }
    self.count++;
    NSTimeInterval delta = link.timestamp - self.lastTime;
    if (delta >= 1.0) {
        CGFloat fps = self.count / delta;
        self.text = [NSString stringWithFormat:@"%.0f FPS", fps];
        self.textColor = fps > 55 ? UIColor.greenColor :
                         fps > 45 ? UIColor.yellowColor : UIColor.redColor;
        self.count = 0;
        self.lastTime = link.timestamp;
    }
}
@end
```

**方案二：RunLoop 卡顿监控（完整实现）**

```objc
// 核心原理：监控 RunLoop 进入 BeforeSources 和 AfterWaiting
// 如果这两个状态之间间隔超过阈值（如 50ms），说明主线程卡顿

@interface LagMonitor : NSObject
@property (nonatomic, assign) CFTimeInterval lastActivity;
@property (nonatomic, strong) dispatch_semaphore_t semaphore;
@end

@implementation LagMonitor

- (void)start {
    self.semaphore = dispatch_semaphore_create(0);
    
    // 1. 创建 RunLoop Observer
    CFRunLoopObserverRef observer = CFRunLoopObserverCreateWithHandler(
        kCFAllocatorDefault,
        kCFRunLoopAllActivities,
        YES, 0,
        ^(CFRunLoopObserverRef obs, CFRunLoopActivity activity) {
            self.lastActivity = CACurrentMediaTime();
        }
    );
    CFRunLoopAddObserver(CFRunLoopGetMain(), observer, kCFRunLoopCommonModes);
    
    // 2. 子线程监控
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        while (YES) {
            long st = dispatch_semaphore_wait(self.semaphore,
                                              dispatch_time(DISPATCH_TIME_NOW, 50 * NSEC_PER_MSEC));
            if (st != 0) { // 超时，说明主线程在 50ms 内没有处理事件
                // 当前主线程正在执行耗时操作
                // 记录当前线程的调用栈
                [self logCallStack];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                // 恢复信号量
                dispatch_semaphore_signal(self.semaphore);
            });
        }
    });
}

- (void)logCallStack {
    // 获取主线程的调用栈（BSBacktraceLogger / PLCrashReporter）
    // 记录到文件，上传到监控平台
}

@end
```

**方案三：第三方成熟方案**

| 框架 | 来源 | 特点 |
|------|------|------|
| **Matrix** | 微信 | RunLoop + 卡顿堆栈捕获 + 内存/文件监控 |
| **GT** | 美团 | 卡顿 + 内存泄漏 + 网络监控一体化 |
| **Listen** | 抖音 | Super Looper 方案替代 RunLoop 监控 |
| **ApmInsight** | 有赞 | 卡顿 + FPS + 堆栈捕获 |

---

## 三、异步绘制（Async Display）

### 3.1 为什么需要异步绘制

主线程绘制（`drawRect`）会阻塞 UI 交互。异步绘制将绘制工作放到子线程，只将绘制结果（Bitmap）在主线程赋值。

### 3.2 实现原理

```
子线程（绘制）:
  UIGraphicsBeginImageContext → CGContext 绘制 → Bitmap

主线程（显示）:
  layer.contents = (id)bitmap — CATransaction 提交后显示
```

### 3.3 异步绘制示例

```objc
// YYAsyncLayer 简化版思想
@implementation AsyncDisplayView

- (void)displayLayer:(CALayer *)layer {
    // 获取当前状态
    NSAttributedString *text = self.text;
    CGSize size = self.bounds.size;
    CGFloat scale = UIScreen.mainScreen.scale;
    
    // 异步绘制
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        UIGraphicsBeginImageContextWithOptions(size, YES, scale);
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        
        // 绘制背景
        [[UIColor whiteColor] setFill];
        UIRectFill(CGRectMake(0, 0, size.width, size.height));
        
        // 绘制文本（使用 Core Text 或 TextKit）
        // ...
        
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        // 回到主线程设置 contents
        dispatch_async(dispatch_get_main_queue(), ^{
            layer.contents = (__bridge id)image.CGImage;
        });
    });
}

@end
```

### 3.4 使用场景

| 场景 | 效果 |
|------|------|
| 大量富文本混排（图文混排） | 主线程不阻塞，滑动流畅 |
| 自定义 Cell 复杂布局 | 每帧计算量转移到子线程 |
| 大量文字的列表（如阅读 App） | 预排版 + 异步绘制，不卡顿 |

**注意**：异步绘制适用于内容**不变**的场景。如果内容频繁变化，频繁创建 Bitmap 反而更耗性能，适合用 CALayer 直接渲染。

---

## 四、列表（UITableView / UICollectionView）优化

### 4.1 核心优化项

| 优化项 | 方案 | 详细 |
|--------|------|------|
| **Cell 复用** | `registerClass + dequeueReusableCell` | 避免每次创建 Cell |
| **高度缓存** | 预计算并缓存 Cell 高度（`estimatedRowHeight` 精确设置） | Cell 高度计算昂贵 |
| **预取** | `UITableViewDataSourcePrefetching` | 提前准备数据 |
| **异步渲染** | 子线程绘制文本和图片 | 主线程只做赋值 |
| **图片降采样** | ImageIO 缩略图解码，内存 48MB → 160KB | 大幅减少图片内存 |
| **Diff 更新** | `reloadData` → Diff 局部更新 | 减少刷新范围 |
| **Cell 重用标记** | `prepareForReuse` 中清理状态 | 避免残留数据错乱 |
| **减少视图层级** | Cell 内扁平化，不用过多容器视图 | — |
| **opaque** | Cell 及子视图 `opaque = YES` | — |
| **iOS 15 Cell Configuration** | 用 `UIListContentConfiguration` | 系统级优化 |

### 4.2 高度缓存方案

```swift
/// 预计算并缓存高度，避免每帧布局前都计算
class HeightCache {
    private var cache: [IndexPath: CGFloat] = [:]
    
    func height(for indexPath: IndexPath, calculator: () -> CGFloat) -> CGFloat {
        if let h = cache[indexPath] { return h }
        let h = calculator()
        cache[indexPath] = h
        return h
    }
    
    func invalidate(_ indexPath: IndexPath) {
        cache.removeValue(forKey: indexPath)
    }
    
    func invalidateAll() {
        cache.removeAll()
    }
}
```

### 4.3 差分更新

```swift
// iOS 13+ DiffableDataSource — 自动计算 diff，无需手动调用 reloadData
var dataSource: UICollectionViewDiffableDataSource<Section, Item>!
var snapshot = NSDiffableDataSourceSnapshot<Section, Item>()

// 只需要更新数据源，系统自动计算 insert/delete/reload
snapshot.appendSections([.main])
snapshot.appendItems(newItems)
dataSource.apply(snapshot, animatingDifferences: true)

// 手动 diff（iOS 12 及以下可以用 IGListKit）
extension Array where Element: Hashable {
    func diff(_ old: [Element]) -> (inserted: [Int], deleted: [Int], moved: [(Int, Int)]) {
        // 实现差异算法（参考 Heckel 算法或 Myers 算法）
    }
}
```

### 4.4 图片降采样（Image Downsampling）

```swift
/// 将大图降采样到目标显示尺寸，避免解码完整大图
/// - 参数：sourceURL 图片文件 URL, pointSize 显示尺寸
/// - 返回：降采样后的 UIImage
func downsampleImage(at sourceURL: URL, to pointSize: CGSize) -> UIImage? {
    let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
    guard let imageSource = CGImageSourceCreateWithURL(sourceURL as CFURL, imageSourceOptions) else {
        return nil
    }
    
    let maxDimension = max(pointSize.width, pointSize.height) * UIScreen.main.scale
    let downsampleOptions = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceShouldCacheImmediately: true,       // 解码成位图
        kCGImageSourceCreateThumbnailWithTransform: true, // 考虑 EXIF 方向
        kCGImageSourceThumbnailMaxPixelSize: maxDimension
    ] as CFDictionary
    
    guard let cgImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions as CFDictionary) else {
        return nil
    }
    return UIImage(cgImage: cgImage)
}
```

---

## 五、内存优化

### 5.1 图片内存优化

**图片内存计算公式：**

```
内存占用 = 图片宽度 × 高度 × 每个像素字节数

颜色空间        字节/像素   示例 (100x100)
sRGB           4 (BGRA)    ≈ 40KB
Wide gamut      8           ≈ 80KB
Alpha-Only      1           ≈ 10KB

加载原图 4000x3000:
  PNG 文件 ≈ 2MB，解码为 Bitmap ≈ 48MB（4000 × 3000 × 4）
  降采样到 200x150 ≈ 120KB
```

| 优化手段 | 做法 | 效果 |
|---------|------|------|
| **降采样** | 用 ImageIO 只解码到显示尺寸 | 48MB → 160KB（极端情况） |
| **子线程解码** | 避免主线程解码卡顿 | — |
| **NSCache（按 cost 淘汰）** | 大图 cost 自动优先淘汰 | 收到 memory warning 时自动清空 |
| **缩略图分离** | 列表用小图详情用大图 | 列表内存大幅降低 |
| **图片格式选择** | WebP / HEIC / AVIF 比 PNG 小 30-50% | 文件小解码内存也少 |
| **downsample 及时性** | 下载后立即降采样，不保留原图 Data | 避免大图常驻内存 |

### 5.2 NSCache 详解

```swift
/// NSCache 特点：
/// 1. 线程安全（无需加锁）
/// 2. 内存不足时自动淘汰
/// 3. 可通过 cost 和 count 限制
/// 4. 本身不拷贝 key（与 NSDictionary 不同）

let cache = NSCache<NSString, UIImage>()
cache.countLimit = 100           // 最多 100 个对象
cache.totalCostLimit = 50 * 1024 * 1024  // 总 cost 上限 50MB

// cost 设置：加载图片时根据图片大小设置 cost
func loadImage(url: URL) -> UIImage? {
    guard let image = downsampleImage(at: url, to: size) else { return nil }
    // 按解码后的 bitmap 大小设置 cost
    let cost = Int(image.size.width * image.size.height * image.scale * image.scale * 4)
    cache.setObject(image, forKey: url.absoluteString as NSString, cost: cost)
    return image
}
```

### 5.3 大图浏览场景优化

```swift
// 采用分片加载 / 平铺（CATiledLayer）方案

class LargeImageViewController: UIViewController {
    private let tiledLayer = CATiledLayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tiledLayer.delegate = self
        tiledLayer.tileSize = CGSize(width: 256, height: 256)  // 每片 256x256
        tiledLayer.levelsOfDetail = 4      // 四级细节
        tiledLayer.levelsOfDetailBias = 3  // 放大级别偏置
        view.layer.addSublayer(tiledLayer)
    }
}

extension LargeImageViewController: CALayerDelegate {
    func draw(_ layer: CALayer, in ctx: CGContext) {
        // 只绘制当前 visible rect 对应的小片
        // 用户滚动/缩放时，CATiledLayer 自动请求新的小片
        let tileRect = ctx.boundingBoxOfClipPath
        // 从大型图片文件中读取对应区域
        drawTile(at: tileRect, in: ctx)
    }
}
```

### 5.4 OOM 检测

```objc
// Jetsam 机制：
// iOS 在内存不足时会发送 memory warning，如果仍不足则 kill 进程

// 监听内存警告
[[NSNotificationCenter defaultCenter] addObserver:self
                                         selector:@selector(handleMemoryWarning)
                                             name:UIApplicationDidReceiveMemoryWarningNotification
                                           object:nil];

// 获取当前 App 内存使用量（用于监控）
#import <mach/task.h>
#import <mach/mach_init.h>

- (uint64_t)memoryUsage {
    task_vm_info_data_t vmInfo;
    mach_msg_type_number_t count = TASK_VM_INFO_COUNT;
    kern_return_t result = task_info(mach_task_self(), TASK_VM_INFO,
                                     (task_info_t)&vmInfo, &count);
    if (result != KERN_SUCCESS) return 0;
    return vmInfo.phys_footprint;
}

// OOM 检测策略：
// 1. 在 App 启动时检查上次运行是否异常退出
// 2. 结合 memory footprint + 是否收到 memory warning
// 3. 如果收到 memory warning 后被杀 → 极高概率是 OOM
```

### 5.5 内存映射文件（mmap）

```objc
// mmap 将文件直接映射到进程内存空间
// 优点：无需将文件全部读入内存、按需分页加载、支持共享内存

int fd = open(filePath, O_RDONLY);
size_t length = lseek(fd, 0, SEEK_END);
void *mapped = mmap(NULL, length, PROT_READ, MAP_PRIVATE, fd, 0);
close(fd);

// 像访问普通内存一样访问文件内容
char *data = (char *)mapped;
// 使用完后 munmap
munmap(mapped, length);

// 应用场景：大文件读取（如数据库、大图片）、日志文件读取
```

### 5.6 内存泄漏检测

| 工具 | 原理 | 使用方式 |
|------|------|---------|
| **Xcode Memory Graph** | 扫描 Heap，检查引用链 | Debug 运行 → 点击 Memory Navigator 的 Debug 按钮 |
| **Instruments Leaks** | 给每个对象打标记，检测释放 | Profile → Leaks |
| **MLeaksFinder** | 控制器/视图消失后延迟检查是否仍然存活 | 集成 SDK，自动弹出泄漏提示 |
| **FBRetainCycleDetector** | 扫描强引用图，检测闭环 | 配合 MLeaksFinder 使用 |

---

## 六、包体积优化

### 6.1 资源优化

| 措施 | 详细 | 效果 |
|------|------|------|
| **清理无用图片** | LSUnusedResources / FengNiao | 删除引用为 0 的图片 |
| **WebP 压缩** | Google WebP，有损压缩比 JPEG 高 30% | 大图从 200KB → 40KB |
| **Asset Catalog** | 编译期 thinning，按设备下载对应尺寸 | 减少下载包大小 |
| **SVG 替代** | 矢量图比 PNG 小，运行时 rasterize | 图标类场景 |
| **音频压缩** | AAC 替代 WAV/MP3 | 文件大小减少 70% |
| **字体子集** | 只包含用到的字符（`fonttools`） | 中文字体从 10MB → 几百 KB |

### 6.2 代码优化

| 措施 | 原理 | 效果 |
|------|------|------|
| **无用代码清理** | `periphery` / `AppCode` 检测未调用方法 | — |
| **LinkMap 分析** | 查看每个 .o 文件大小，定位大模块 | 找到优化目标 |
| **Swift 替代 OC** | Swift 泛型代码少、metadata 少 | 二进制更小 |
| **静态库合并** | 多个静态库合并，减少 section 数量 | — |
| **编译器优化** | `-Osize` 优化模式 | 以速度为代价减小体积 |
| **Metadata Stripping** | `-Wl,-dead_strip` + `-fvisibility=hidden` | 删除未引用的符号 |
| **+load 迁移** | +load 方法会增加 __objc_nlclslist section | — |

### 6.3 App Thinning

```
App Thinning 包含三种技术：

① Slicing（切片）：
   App Store 根据用户设备，只下载对应架构和分辨率的 slice
   例：iPhone 15 Pro 只下载 arm64 + @3x 资源

② Bitcode：
   中间表示（IR），App Store 重新编译优化
   未来可能被移除（Apple 逐渐弱化）

③ On-Demand Resources（按需资源）：
   将资源（如 Level 2-10 的关卡数据）标记为 ODR
   首次下载只包含 Level 1，后续按需下载
   tag 管理，系统自动清理不再使用的 tag
```

### 6.4 LinkMap 分析脚本

```bash
# 1. 在 Xcode Build Settings 设置：
#    Write Link Map File → YES
#    Path → 默认路径

# 2. 使用脚本分析 LinkMap
# LinkMap 文件格式：
# # Sections:
# # Address    Size        File
# 0x100000000 0x000123ABC (path/to/a.o)
# 0x100012000 0x000045678 (path/to/b.o)

# 3. 按模块/类统计大小
grep "\.o)" /path/to/LinkMap.txt | \
  awk -F '[\t ]+' '{sum[$4] += strtonum("0x"$2)} END \
    {for (k in sum) printf "%.2fMB\t%s\n", sum[k]/1048576, k}' | \
  sort -rn | head -20
```

---

## 七、网络优化

### 7.1 网络层优化

| 优化点 | 做法 | 原理 |
|--------|------|------|
| **HTTPDNS** | 使用 HTTPDNS 替代 Local DNS | 防止 DNS 劫持、更快的解析 |
| **连接复用** | HTTP/2 多路复用 / HTTP/1.1 Keep-Alive | 减少建立连接次数 |
| **数据压缩** | Gzip / Brotli 压缩请求和响应体 | 减少传输量 |
| **缓存策略** | Cache-Control / ETag / Last-Modified | 减少请求次数 |
| **预加载** | 空闲时提前获取可能用到的数据 | 用户看到时已有数据 |
| **请求合并** | 多个小请求合并为一个大请求 | 减少 HTTP 开销 |
| **Protocol 升级** | HTTP/2 → HTTP/3 (QUIC) | 更快的连接、更好的弱网表现 |
| **图片 CDN** | CDN 加速 + 图片裁剪（按需尺寸+质量） | 加载更快 |

### 7.2 缓存策略细节

```swift
// NSURLCache 统一管理缓存
let config = URLSessionConfiguration.default
config.requestCachePolicy = .returnCacheDataElseLoad
config.urlCache = URLCache(memoryCapacity: 20 * 1024 * 1024,   // 20MB 内存
                           diskCapacity: 100 * 1024 * 1024,    // 100MB 磁盘
                           diskPath: "NetworkCache")
config.timeoutIntervalForRequest = 15

// 服务端配合
// Cache-Control: max-age=3600, public
// ETag: "abc123"
// Last-Modified: Wed, 21 Jun 2023 07:28:00 GMT

// 客户端条件请求（如果缓存过期，发送 If-None-Match / If-Modified-Since）
// 服务端返回 304 Not Modified → 使用缓存
```

### 7.3 NSURLProtocol 网络拦截

```objc
// 可以用 NSURLProtocol 实现自定义网络层（拦截和修改请求）
// 应用场景：
//   1. 离线缓存（为 H5 页面做离线包）
//   2. 网络调试（记录所有请求）
//   3. 流量统计
//   4. 请求重定向（如静态资源替换为本地）

@interface CustomProtocol : NSURLProtocol
@end

@implementation CustomProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    // 避免递归处理（已经处理过的请求打标记）
    if ([NSURLProtocol propertyForKey:@"CustomProtocolHandled" inRequest:request]) {
        return NO;
    }
    return [request.URL.absoluteString containsString:@"example.com"];
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    return request;
}

- (void)startLoading {
    NSMutableURLRequest *req = [self.request mutableCopy];
    [NSURLProtocol setProperty:@YES forKey:@"CustomProtocolHandled" inRequest:req];
    
    // 可以修改请求头、替换本地资源等
    // 然后发起真实请求
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                          delegate:self
                                                     delegateQueue:nil];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:req];
    [task resume];
}

@end

// 注册
[NSURLProtocol registerClass:[CustomProtocol class]];
```

### 7.4 QUIC / HTTP/3

```
QUIC (Quick UDP Internet Connections) 特性：

① 0-RTT 握手（再次连接时无需往返）
② 连接迁移（从 WiFi 切换到 蜂窝 不中断）
③ 队头阻塞解决（TCP 丢包会影响所有流，QUIC 只影响单个流）
④ 内置 TLS 1.3（加密是必须的）

与 HTTP/2 对比：
┌────────────────┬──────────────────┬──────────────────┐
│    特性         │ HTTP/2 (TCP)     │ HTTP/3 (QUIC)    │
├────────────────┼──────────────────┼──────────────────┤
│ 传输层          │ TCP              │ UDP              │
│ 握手次数        │ 3-RTT (TCP+TLS)  │ 1-RTT / 0-RTT    │
│ 队头阻塞        │ 存在（TCP 层面）│ 不存在（单流隔离）│
│ 连接迁移        │ 不支持           │ 支持             │
│ 操作系统支持    │ 广泛             │ iOS 14+ / macOS 11+
└────────────────┴──────────────────┴──────────────────┘
```

---

## 八、I/O 优化

### 8.1 文件读取优化

```objc
// ✅ 推荐：预读 + 批量写入
// ❌ 不推荐：频繁小文件读取

// 方案一：dispatch_io 批量读取（GCD IO）
dispatch_io_t io = dispatch_io_create_with_path(
    DISPATCH_IO_STREAM, filePath, O_RDONLY, 0,
    dispatch_get_global_queue(0, 0), ^(int error) { }
);

dispatch_io_read(io, 0, SIZE_MAX, dispatch_get_global_queue(0, 0), ^(bool done, dispatch_data_t data, int error) {
    // 批量读取，系统自动合并
});

// 方案二：pread（定位读取，不会影响文件偏移）
ssize_t pread(int fd, void *buf, size_t count, off_t offset);
// 线程安全，不需要加锁

// 方案三：mmap（内存映射）
// 见内存优化章节
```

### 8.2 数据库优化（SQLite）

```sql
-- 1. 批量写入用事务
BEGIN TRANSACTION;
INSERT INTO t VALUES (1, 'a');
INSERT INTO t VALUES (2, 'b');
COMMIT;

-- 2. 预编译语句（Prepared Statement）
sqlite3_prepare_v2(db, "INSERT INTO t VALUES (?, ?)", -1, &stmt, NULL);
for (int i = 0; i < 1000; i++) {
    sqlite3_bind_int(stmt, 1, i);
    sqlite3_bind_text(stmt, 2, [string UTF8String], -1, NULL);
    sqlite3_step(stmt);
    sqlite3_reset(stmt);
}
sqlite3_finalize(stmt);

-- 3. WAL 模式（Write-Ahead Logging）
PRAGMA journal_mode=WAL;
-- 读不阻塞写，写不阻塞读

-- 4. 适当创建索引
CREATE INDEX idx_user_id ON t(user_id);

-- 5. 控制事务大小（避免太大锁太久）
-- 每次提交 500-1000 条
```

### 8.3 日志写入优化

```objc
// ❌ 不推荐：每次日志写入直接写文件
// NSLog 或 write 主线程会卡

// ✅ 推荐：异步批量写入
@interface AsyncLogger : NSObject
@property (nonatomic, strong) dispatch_queue_t ioQueue;
@property (nonatomic, strong) NSMutableString *buffer;
@end

@implementation AsyncLogger

- (instancetype)init {
    self = [super init];
    if (self) {
        _ioQueue = dispatch_queue_create("com.logger.io", DISPATCH_QUEUE_SERIAL);
        _buffer = [NSMutableString string];
        
        // 定时批量刷盘（如每 3 秒或 buffer 达到 10KB）
        dispatch_source_t timer = dispatch_source_create(
            DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _ioQueue);
        dispatch_source_set_timer(timer,
            dispatch_walltime(NULL, 0), 3 * NSEC_PER_SEC, 0);
        dispatch_source_set_event_handler(timer, ^{
            [self flush];
        });
        dispatch_resume(timer);
    }
    return self;
}

- (void)log:(NSString *)message {
    dispatch_async(self.ioQueue, ^{
        [self.buffer appendString:message];
        [self.buffer appendString:@"\n"];
        if (self.buffer.length > 10 * 1024) {
            [self flush];
        }
    });
}

- (void)flush {
    // 将 buffer 写入文件
    // append 模式，写入后清空 buffer
}

@end
```

---

## 九、电量优化

| 维度 | 优化措施 | 原理 |
|------|---------|------|
| **定位** | 降低精度（`kCLLocationAccuracyHundredMeters`）、延长更新间隔、用完关闭 | GPS 硬件耗电高 |
| **网络** | 合并请求、非前台时降低频率、大文件在 WiFi 下下载 | 蜂窝网络耗电 |
| **CPU** | 避免空转轮询、`dispatch_source` 定时器替代 NSTimer | NSTimer 会唤醒主线程 |
| **GPU** | 降低帧率（`CADisplayLink.preferredFramesPerSecond`） | GPU 渲染频率降低 |
| **后台** | 用 `BGTaskScheduler` 替代`Background Fetch` | 系统统一调度更节能 |
| **I/O** | 批量写入替代频繁小文件写入 | 减少磁盘寻道和唤醒 |
| **Idle** | 空闲时降低线程优先级（`QOS_CLASS_BACKGROUND`） | 不影响前台交互 |

---

## 十、Instruments 调试工具

### 10.1 工具速查

| 工具 | 用途 | 关键指标 |
|------|------|---------|
| **Time Profiler** | CPU 耗时分析 | 各方法执行时间占 CPU 时间的百分比 |
| **Core Animation** | GPU 渲染分析 | 混合/离屏渲染/像素对齐 |
| **Leaks** | 内存泄漏 | 泄漏对象及其引用链 |
| **Allocations** | 内存分配 | 对象创建/释放、堆内存总量 |
| **Energy Log** | 电量消耗 | 各模块能耗占比 |
| **Network** | 网络请求 | 请求耗时、传输量、DNS 时间 |
| **File Activity** | I/O 操作 | 文件读写频率和大小 |
| **System Trace** | 系统调用 | 内核态耗时、线程状态转换 |

### 10.2 Core Animation 调试选项详解

| 选项 | 颜色含义 | 优化目标 |
|------|---------|---------|
| **Color Blended Layers** | 红色 = 需要 alpha blend 的图层 | 减少红色，设置 `opaque = YES` |
| **Color Hits Green and Misses Red** | 绿 = 栅格化命中，红 = 未命中 | 减少红色，`shouldRasterize` 只用于不变视图 |
| **Color Copied Images** | 蓝色 = GPU 不支持的格式，需要 CPU 拷贝 | 减少蓝色，使用 GPU 支持的格式（如 BGRA8888） |
| **Color Misaligned Images** | 黄 = 缩放，紫 = 像素不对齐 | 图片 size 与显示 size 一致 |
| **Color Offscreen-Rendered Yellow** | 黄色 = 离屏渲染 | 减少黄色区域 |
| **Color OpenGL Fast Path Blue** | 蓝色 = 使用 GPU 快速路径 | — |

### 10.3 Time Profiler 使用技巧

```
启动 Time Profiler → 操作 App → Stop → 分析 Call Tree

Call Tree 设置：
  Separate by Thread	— 按线程分开
  Invert Call Tree	— 叶子节点在上（看最深层方法）
  Hide System Libraries	— 只看自己的代码
  Flatten Recursion	— 扁平化递归调用
  Symbolicate		— 符号化（确保 dsym 文件可用）

分析技巧：
  1. 把耗时最长的调用链展开
  2. 检查哪一段代码在短时间内被大量执行
  3. 注意阻塞主线程的方法（应该异步处理）
```

---

## 十一、面试题

### 1. App 启动优化可以从哪些方面入手？具体有哪些手段？

**Pre-main**：减少动态库数量、使用 order file 二进制重排、+load 方法迁移到懒加载、减少 C++ 全局变量、清理无用类/方法。

**Main 后**：SDK 延迟初始化、首屏预渲染、子线程预加载数据、方法结果缓存、AppDelegate 瘦身。

**可用 `DYLD_PRINT_STATISTICS` 测量 pre-main 耗时，用二进制重排减少缺页中断。**

### 2. 什么是离屏渲染？哪些情况会触发？如何优化？

离屏渲染是 GPU 在当前帧缓冲区外开辟额外缓冲区进行渲染，需要上下文切换和额外数据拷贝，性能差。

**触发条件**：圆角+clipsToBounds、阴影、mask、groupOpacity、shouldRasterize、drawRect。

**优化**：圆角用 UIBezierPath 裁剪绘制图片、阴影用 shadowPath、drawRect 改用异步绘制、shouldRasterize 只在内容不变时使用。

### 3. 如何监控 App 卡顿？有哪些成熟的方案？

**CADisplayLink 监控 FPS**：每秒统计回调次数，低于 50 即为卡顿。

**RunLoop 监控**：主线程 RunLoop 在 BeforeSources 和 AfterWaiting 之间设置 50ms 超时，超时则触发卡顿记录和堆栈捕获。

**成熟方案**：微信 Matrix、抖音 Listen（Super Looper）、美团 GT。

### 4. 如何优化列表（UITableView/UICollectionView）的流畅性？

Cell 复用、高度缓存、预取（Prefetching）、异步渲染、图片降采样、DiffableDataSource 差分更新、避免离屏渲染、opaque=YES、减少 Cell 视图层级、iOS 15 的 Cell Configuration。

### 5. 图片降采样的原理是什么？为什么要做？

图片解码为 Bitmap 时按原始尺寸分配内存（4000x3000 PNG 解码为 Bitmap 约 48MB），降采样通过 ImageIO 只解码到目标显示尺寸（200x150 约 120KB），避免不必要的内存占用。使用 `CGImageSourceCreateThumbnailAtIndex` + `kCGImageSourceThumbnailMaxPixelSize` 实现。

### 6. 包体积优化有哪些手段？

**资源**：清理无用图片、WebP 压缩、Asset Catalog、SVG 替代、ODR 按需资源、字体子集。

**代码**：LinkMap 分析定位大模块、无用代码清理、`-Osize` 编译优化、symbol stripping、Swift 替代 OC。

**编译**：App Thinning（Slicing + Bitcode + ODR），减少下载包大小。

### 7. 为什么离屏渲染会影响性能？离屏渲染和 CPU 渲染有什么区别？

离屏渲染需要：① 开辟新的帧缓冲区；② 切换渲染上下文（当前→离屏→当前）；③ 至少两次渲染（离屏渲染+合成）。在 iPhone 6/6s 时代影响尤其明显。

**CPU 渲染**完全在 CPU 上用 Core Graphics 绘制 Bitmap，然后上传到 GPU 显示。**GPU 离屏渲染**是在 GPU 上开辟新缓冲区渲染。两者都会引起性能问题，但 CPU 渲染可以异步执行（子线程绘制），而 GPU 离屏渲染在主线程的渲染管线中同步执行。

### 8. 什么是 OOM？如何检测和定位？

OOM（Out-Of-Memory）即 Jetsam 机制杀掉 App。iOS 没有内存交换（swap），超过系统阈值直接 kill。

**检测**：启动时检查上次是否异常退出 + 是否收到 memory warning。使用 `task_info` 获取 `phys_footprint` 监控内存使用。美团有成熟的 OOM 检测方案（检测 user trip 日志结合 memory footprint）。

**定位**：Instruments Allocations / Memory Graph 分析大对象创建和泄漏。

### 9. 什么是二进制重排（Order File）？有什么用？

利用 Clang 的 SanitizerCoverage 收集启动时所有函数调用顺序，生成 order file。在编译时按照这个顺序排列代码，使得启动路径上的代码在物理内存中连续，减少 Page Fault 次数。微信通过此优化使 pre-main 时间从 1200ms 降至 600ms。

### 10. 异步绘制是怎么实现的？什么时候用？

子线程创建 Bitmap context（`UIGraphicsBeginImageContext`），在上下文中绘制文本/图片等内容，然后主线程将 `layer.contents` 设为该 Bitmap。

**适用场景**：富文本混排、大量文字的列表、自定义复杂的 Cell 绘制。内容不变或变化少时效果好。

**不适用**：内容频繁变化的场景（如视频帧、动画），频繁创建销毁 Bitmap 更耗性能。

### 11. NSCache 和 NSMutableDictionary 有什么区别？

1. **线程安全**：NSCache 是线程安全的，不需要加锁
2. **自动淘汰**：收到 memory warning 时自动清空；NSDictionary 不会
3. **不拷贝 Key**：NSCache 不拷贝 key 对象（字典会 copy）
4. **按 Cost 淘汰**：可以设置 totalCostLimit，大对象优先淘汰
5. **Eviction 回调**：`cache:willEvictObject:` 可以在淘汰时做清理

### 12. mmap 是什么？在 iOS 开发中有什么应用场景？

`mmap` 将文件映射到进程内存地址空间，操作系统按需将文件页加载到内存。不是一次性读入整个文件。

**应用场景**：
- 大文件读取（超大图片、视频文件）
- 数据库文件映射（SQLite 底层使用 mmap）
- 热修复框架（补丁文件映射）
- 日志文件读取

### 13. WAL 模式对 SQLite 有什么好处？

WAL（Write-Ahead Logging）模式：写操作时，只追加写入 WAL 文件，不直接操作主数据库文件。

**优点**：
- **读不阻塞写，写不阻塞读**：传统的 delete 模式中，写事务会阻塞读
- **写性能更好**：顺序追加写入比随机写入快
- **读取更快**：读取时可以同时写入，不需要等待锁

**缺点**：
- WAL 文件需要 checkpoint 机制回收
- 对文件系统有一定要求

### 14. Instruments 的 Time Profiler 怎么使用？Call Tree 各选项的含义？

Profile → Time Profiler → 操作 App → 停止 → 分析 Call Tree。

- **Separate by Thread**：按线程查看各线程耗时
- **Invert Call Tree**：最底层的方法排在最前面（方便看到最终消耗 CPU 的方法）
- **Hide System Libraries**：只看自己的代码，排除系统库
- **Flatten Recursion**：递归调用只统计一次，方便看总时间
- **Symbolicate**：符号化，确保 dsym 文件存在

**分析技巧**：关注「调用次数极多」的方法，即使单次耗时短，大量调用也会导致卡顿。

### 15. iOS 电量优化的要点？

- 降低定位精度和频率
- 合并网络请求，非前台降低频率
- `dispatch_source` 定时器替代 NSTimer
- 减少离屏渲染和降低帧率
- `BGTaskScheduler` 替代 Background Fetch
- 批量写入代替频繁小 I/O
- 后台任务用 `QOS_CLASS_BACKGROUND` 优先级
