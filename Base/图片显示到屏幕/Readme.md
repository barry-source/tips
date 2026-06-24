# 图片是如何显示到屏幕上的

## 一、总览：全链路流程

一张图片从数据到显示在屏幕上，经历了 CPU、GPU、RunLoop、CoreAnimation 等多个组件的协作：

```
┌────────────────────────────────────────────────────────────────────┐
│  App 层：UIImageView.image = image                                  │
└──────────────────────────┬─────────────────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────────────────┐
│  Step 1：图片解码（CPU / 子线程）                                    │
│  JPEG/PNG/WebP → CGImageRef → Bitmap 位图                          │
└──────────────────────────┬─────────────────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────────────────┐
│  Step 2：CALayer 提交（CPU / 主线程）                                │
│  UIImageView.layer.contents = CGImageRef                           │
│  → 当前 RunLoop 的 CoreAnimation 事务被标记为需要提交                 │
└──────────────────────────┬─────────────────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────────────────┐
│  Step 3：RunLoop 触发 CATransaction 提交（CPU / 主线程）             │
│  BeforeWaiting / 自定义 CATransaction flush 时机                    │
│  → Layer Tree → Presentation Tree → Render Tree                    │
└──────────────────────────┬─────────────────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────────────────┐
│  Step 4：Render Server 接管（独立进程）                              │
│  SpringBoard 的 backboardd 进程                                    │
│  → 解析 Render Tree → 生成 OpenGL ES / Metal 绘制指令                │
└──────────────────────────┬─────────────────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────────────────┐
│  Step 5：GPU 渲染（硬件）                                            │
│  OpenGL ES / Metal 管线                                             │
│  顶点着色器 → 光栅化 → 片段着色器 → 逐像素写入 Framebuffer            │
└──────────────────────────┬─────────────────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────────────────┐
│  Step 6：Vsync 信号触发帧切换（硬件时序）                             │
│  GPU 完成 → 等待 Vsync → 交换 Buffer → 显示到屏幕                    │
└────────────────────────────────────────────────────────────────────┘
```

---

## 二、Step 1：图片解码（CPU 子线程）

### 2.1 为什么图片需要解码？

图片的存储格式（JPEG、PNG）是**压缩数据**，不能被 GPU 直接用于渲染。必须先解码为**位图（Bitmap）**——即每个像素点包含 RGBA 四个通道的原始像素数据。

```
JPEG 文件（200KB）                    PNG 文件（500KB）
    │                                     │
    ▼                                     ▼
┌─────────────┐                    ┌─────────────┐
│ DCT 逆变换   │                    │  zlib 解压缩 │
│ Huffman 解码 │                    │  Filter 还原 │
│ 颜色空间转换 │                    │  Adam7 插值  │
└──────┬──────┘                    └──────┬──────┘
       │                                  │
       └────────────────┬─────────────────┘
                        ▼
              位图（Bitmap）：4000×3000×4 = 48MB
              每个像素：R(8bit) G(8bit) B(8bit) A(8bit)
```

### 2.2 显式解码 vs 隐式解码

```objc
// ❌ 隐式解码（系统自动，主线程）
UIImage *image = [UIImage imageNamed:@"photo"]; // 此时还未完全解码
imageView.image = image; // CoreAnimation 渲染时会触发解码 → 主线程卡顿

// ✅ 显式解码（子线程提前完成）
dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
    // 子线程解码
    CGImageRef cgImage = [self decodeImageInBackground:data];
    dispatch_async(dispatch_get_main_queue(), ^{
        imageView.image = [UIImage imageWithCGImage:cgImage];
    });
});
```

### 2.3 解码的几种实现方式

```objc
// 方式 1：CGImageSource 解码（推荐）
- (CGImageRef)decodeImageWithData:(NSData *)data {
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    CGImageRef cgImage = CGImageSourceCreateImageAtIndex(source, 0, NULL);
    CFRelease(source);

    // 强制解码：创建 bitmap context，将 CGImage 绘制进去
    size_t width = CGImageGetWidth(cgImage);
    size_t height = CGImageGetHeight(cgImage);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL, width, height,
                                                 8, 0, colorSpace,
                                                 kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedFirst);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgImage);
    CGImageRef decodedImage = CGBitmapContextCreateImage(context);

    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    CGImageRelease(cgImage);
    return decodedImage;
}

// 方式 2：UIImage + force decode（SDWebImage 做法）
// 将 image 绘制到位图 context 后再取回，触发实际解码
UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
[image drawAtPoint:CGPointZero];
UIImage *decodedImage = UIGraphicsGetImageFromCurrentImageContext();
UIGraphicsEndImageContext();

// 方式 3：ImageIO 降采样解码（大图场景）
// 只解码目标尺寸的位图，避免全量解码
NSDictionary *options = @{
    (id)kCGImageSourceThumbnailMaxPixelSize: @(MAX(targetWidth, targetHeight)),
    (id)kCGImageSourceCreateThumbnailFromImageAlways: @YES,
    (id)kCGImageSourceShouldCacheImmediately: @YES,
};
CGImageRef thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, (__bridge CFDictionaryRef)options);
```

### 2.4 解码的内存占用计算

```
位图大小 = 宽度 × 高度 × 每像素字节数（4 bytes，RGBA 8888）

常见场景：
  60×60 缩略图     = 60 × 60 × 4     = 14.4 KB
  375×375 中等图    = 375 × 375 × 4   = 562.5 KB
  750×1334 全屏图   = 750 × 1334 × 4  = 4 MB
  1242×2208 大图    = 1242 × 2208 × 4 = 10.7 MB
  4000×3000 原图    = 4000 × 3000 × 4 = 48 MB
```

### 2.5 字节对齐优化

iOS 中 CGBitmapContextCreate 创建的位图，每行字节数必须是 16 字节的倍数：

```objc
// 系统实际分配的内存通常比理论值大
size_t bytesPerRow = width * 4;           // 理论值
bytesPerRow = (bytesPerRow + 15) & ~15;    // 对齐到 16 的倍数
```

**实际影响**：一张 60×60 的图片，理论 14400 字节，对齐后实际占用 64×60 = 3840 字节（对齐后的 bytesPerRow = 64）。

---

## 三、Step 2：CALayer 提交（CPU 主线程）

### 3.1 UIView 与 CALayer 的关系

每一个 UIView 内部都有一个 CALayer（`layer` 属性），负责实际的内容管理和渲染：

```
UIView                                      ← App 层，负责事件处理
  └── CALayer                               ← 显示层，负责内容管理
        ├── .contents = CGImageRef           ← 静态内容（图片）
        ├── .backgroundColor                ← 背景色
        ├── .cornerRadius                   ← 圆角
        ├── .shadow*                        ← 阴影
        └── .sublayers                      ← 子层
```

**当设置 `imageView.image = image` 时，UIKit 将 image 的 CGImageRef 赋值给 layer.contents。**

### 3.2 CoreAnimation 三棵树

```
┌─────────────────────────────────────────────────────────────────┐
│                       Layer Tree（模型树）                        │
│  运行在主线程，存储所有 Layer 的属性（frame、contents、opacity）    │
│  可以被任意修改                                                   │
│                                                                  │
│                          │  CATransaction commit                 │
│                          ▼                                       │
│                   Presentation Tree（展示树）                      │
│  存储当前屏幕上实际显示的 Layer 属性                                │
│  属性值可能被动画插值                                             │
│                                                                  │
│                          │  Render Server 读取                   │
│                          ▼                                       │
│                    Render Tree（渲染树）                           │
│  扁平化的渲染指令集合，不包含 Layer 对象信息                         │
│  由 Render Server 解析并生成绘制指令                                │
└─────────────────────────────────────────────────────────────────┘
```

**关键点**：
- `CALayer.presentationLayer` 可以获取展示树上的当前值（如动画中间帧）
- `CALayer.modelLayer` 获取模型树的值（最终状态）
- 渲染树是扁平化的——iOS 会尝试合并相邻层的渲染

---

## 四、Step 3：RunLoop 与 CoreAnimation 事务提交

### 4.1 RunLoop 的基本模型

```
          ┌─────────────────────────────────────────────┐
          │                RunLoop                       │
          │                                              │
          │  ┌─ 接收到 Source 事件（触摸/定时器） ────┐   │
          │  │  处理事件、修改 Layer 属性               │   │
          │  │  → 标记 CATransaction 需要提交          │   │
          │  └────────────────────────────────────────┘   │
          │                      │                        │
          │  ┌─ BeforeWaiting：───────────────────────┐   │
          │  │  CATransaction commit                   │   │
          │  │  → 将 Layer Tree 转成 Render Tree       │   │
          │  │  → 通过 XPC/Mach IPC 发给 Render Server│   │
          │  └────────────────────────────────────────┘   │
          │                      │                        │
          │  ┌─ 休眠 ────────────────────────────────┐   │
          │  │  等待新的事件或 Vsync 信号              │   │
          │  └────────────────────────────────────────┘   │
          └─────────────────────────────────────────────┘
```

### 4.2 RunLoop Mode

```objc
// iOS 中常见的 RunLoop Mode
UITrackingRunLoopMode       // 滚动时（UIScrollView 滑动）
NSDefaultRunLoopMode        // 默认状态
NSRunLoopCommonModes        // 包含以上两个

// 影响：滚动时图片加载可能被延迟
// 图片加载任务设置到 CommonModes，确保滚动时也能完成
```

### 4.3 CATransaction 的提交时机

```objc
// 隐式事务：系统自动管理
// 当 RunLoop 进入 BeforeWaiting 时（等待下一次事件前），自动提交
- (void)viewDidLoad {
    self.imageView.image = image;       // 标记脏区域
    self.imageView.frame = newFrame;    // 标记脏区域
    // RunLoop 将要休眠时 → CATransaction 提交 → 一次渲染
}

// 显式事务：手动批量提交
[CATransaction begin];
self.imageView.image = image1;
self.imageView.image = image2;
self.imageView.image = image3;
[CATransaction commit]; // 只渲染一次（取 image3 的最终值）

// 事务完成回调
[CATransaction setCompletionBlock:^{
    NSLog(@"渲染完成");
}];
```

### 4.4 RunLoop 与 UI 卡顿的关系

```
一帧的预算时间：16.67ms（60fps）或 8.33ms（120fps）

如果 RunLoop 一次循环中：
  事件处理 + Layout + Display + CATransaction 提交 > 16.67ms
  → 当前帧无法在 Vsync 前完成
  → 丢帧、卡顿

常见原因：
  ✅ 主线程解码大图（→ 应在子线程解码）
  ✅ 复杂的主线程计算（→ 异步计算）
  ✅ 大量的离屏渲染（→ 减少 cornerRadius/shadow）
  ✅ 大量的 CA 动画并发（→ 控制动画数量）
```

---

## 五、Step 4：Render Server 接管（独立进程）

### 5.1 进程模型

iOS 的渲染是**跨进程**架构：

```
    App 进程（沙箱内）                          Render Server 进程
┌──────────────────────┐          XPC        ┌──────────────────────┐
│  CoreAnimation       │ ──── Mach IPC ────▶ │  backboardd          │
│  → Layer Tree        │          IPC         │  → 解析 Render Tree  │
│  → Presentation Tree │ ◀─────── ACK ────── │  → 生成 OpenGL/Metal │
│  → Render Tree       │                     │    绘制指令          │
└──────────────────────┘                     └──────────────────────┘
```

**设计优势**：
1. **安全性**：App 崩溃不会导致屏幕残留或花屏
2. **性能**：Render Server 可以利用独立的 GPU 时间片
3. **隔离**：App 不能直接操作 GPU，避免恶意代码
4. **统一管理**：系统可以跨 App 协调渲染（如转场动画）

### 5.2 Render Tree 的优化

Render Tree 与 Layer Tree 不同——它做了**扁平化**处理：

```
Layer Tree（层级结构）           Render Tree（扁平结构）
┌──────────────────┐           ┌──────────────────┐
│ UIView (透明)     │           │ 绘制指令序列      │
│  ├─ UIImageView   │           │  1. 绘制红色背景  │
│  │   └─ CALayer   │           │  2. 绘制图片 A   │
│  └─ UILabel       │           │  3. 绘制文字 B   │
│      └─ CALayer   │           │  ...             │
└──────────────────┘           └──────────────────┘
```

**优化效果**：如果父 View 是透明的（`opaque = NO`），所有子 View 会合并到同一绘制指令中，减少绘制次数。

---

## 六、Step 5：GPU 渲染管线

### 6.1 GPU 渲染管线全景

```
┌──────────────────────────────────────────────────────────────────┐
│                    GPU 图形渲染管线                                  │
│                                                                  │
│  顶点数据      顶点着色器      光栅化       片段着色器   逐像素操作    │
│  (Vertices) ─▶ (Vertex   ─▶ (Raster- ─▶ (Fragment ─▶ (Per-      │
│                Shader)       ization)     Shader)     Fragment   │
│                                                        Ops)      │
│                                                         │        │
│  GPU 从 Render Server     将几何图形      每个像素    深度测试    │
│  收到绘制指令            转换为像素网格    计算颜色    模板测试    │
│                                                        混合      │
│                                                         │        │
│                                                         ▼        │
│                                                  Framebuffer     │
└──────────────────────────────────────────────────────────────────┘
```

### 6.2 各阶段详解

| 阶段 | 工作内容 | 输入 → 输出 |
|------|---------|------------|
| **顶点着色器** | 将顶点从模型坐标→世界坐标→视口坐标→屏幕坐标 | 顶点数据 → 标准化设备坐标 |
| **光栅化** | 将几何图元（三角形/线段）转换为像素片段 | 顶点 → 待计算的片段（像素）集合 |
| **片段着色器** | 计算每个像素的最终颜色（纹理采样、光照计算） | 片段 → 颜色值（RGBA） |
| **逐像素操作** | 深度测试、模板测试、透明度混合 | 片段颜色 → Framebuffer 像素 |

### 6.3 纹理上传

图片的 CGImageRef（位图）需要上传到 GPU 显存成为**纹理**：

```
CPU 内存（App 进程）          GPU 显存（GPU 进程）
┌──────────────────┐        ┌──────────────────┐
│  Bitmap Data     │ ────▶  │  纹理（Texture）  │
│  48MB 原始位图   │        │  压缩纹理 / 原始  │
│                  │        │  格式由 GPU 决定  │
└──────────────────┘        └──────────────────┘
```

纹理上传是**耗时操作**，GPU 需要从 CPU 内存读取数据到自己的显存。这个操作通过 DMA（Direct Memory Access）完成。

### 6.4 离屏渲染

离屏渲染（Off-screen Rendering）是指 GPU 在当前屏幕缓冲区外另开一个缓冲区进行渲染。

```
屏幕渲染（On-screen）：                         离屏渲染（Off-screen）：
┌──────────────────────┐                 ┌──────────────────────┐
│  GPU → Framebuffer   │                 │  GPU → Offscreen      │
│       → Display      │                 │       Buffer          │
└──────────────────────┘                 │          │            │
  直接显示，无额外开销                    │          ▼            │
                                        │  GPU → Framebuffer     │
                                        │       → Display        │
                                        └──────────────────────┘
                                       需要上下文切换，两次渲染
```

**触发离屏渲染的情况**：

```objc
// ⚠️ 以下操作会触发离屏渲染，应谨慎使用
view.layer.cornerRadius = 10;            // ✅ 仅 cornerRadius 不触发
view.layer.masksToBounds = YES;          // ✅ 两个同时设置 → 触发离屏
view.layer.shadowColor = ...;            // ✅ 阴影 → 触发离屏
view.layer.shadowOpacity = 0.5;
view.layer.shadowOffset = CGSizeMake(0, -3);
view.layer.shadowRadius = 3;
view.layer.allowsGroupOpacity = YES;     // ✅ 组透明度 → 触发离屏
view.layer.shouldRasterize = YES;        // ✅ 光栅化 → 触发离屏
view.layer.mask = ...;                   // ✅ 遮罩 → 触发离屏
```

**什么时候离屏渲染是值得的？**

| 场景 | 建议 | 原因 |
|------|------|------|
| 静态圆角（一次设置） | 用 `cornerRadius + masksToBounds` | 离屏渲染一次，后续复用 |
| 动态列表（cell 复用） | 用贝塞尔曲线裁剪 | 每次滚动都会重新离屏渲染 |
| 复杂阴影 | 用 `shouldRasterize = YES` | 光栅化后缓存，避免每帧重绘 |
| 简单阴影 | 用 `shadowPath` 替代 | 指定路径后不触发离屏 |

### 6.5 CPU 渲染 vs GPU 渲染

| 维度 | CPU 渲染 | GPU 渲染 |
|------|---------|---------|
| **适用场景** | 少量、复杂、自定义绘制 | 大量、简单、重复绘制 |
| **实现方式** | `drawRect:` / CoreGraphics | CoreAnimation / SpriteKit / SceneKit |
| **性能** | 并行度低，适合复杂计算 | 并行度高，适合简单重复计算 |
| **内存** | 不占用 GPU 显存 | 需要纹理上传 |
| **电池** | 高功耗 | 低功耗 |
| **何时使用** | 文字渲染、PDF 绘制 | 图片显示、动画、游戏 |

---

## 七、Step 6：Vsync 与屏幕刷新

### 7.1 Vsync 信号机制

```
          ┌──────────┐    ┌──────────┐    ┌──────────┐
Vsync     │          │    │          │    │          │
信号 ────▶│  第 N 帧  │───▶│  第 N+1  │───▶│  第 N+2  │  ...
          │  显示    │    │  帧显示  │    │  帧显示  │
          └──────────┘    └──────────┘    └──────────┘
             16.67ms         16.67ms         16.67ms
```

```
60Hz 屏幕：每 16.67ms 一个 Vsync 信号
120Hz 屏幕：每 8.33ms 一个 Vsync 信号

Vsync 信号的作用：
  1. 通知 GPU 将 framebuffer 发送到显示器
  2. 通知 App 可以开始准备下一帧
```

### 7.2 双缓冲与三缓冲

#### 双缓冲（Double Buffering）

```
     显示器                     GPU
  ┌──────────┐           ┌──────────┐
  │ Front    │◀────显示──│           │
  │ Buffer   │           │           │
  ├──────────┤           ├──────────┤
  │ Back     │◀────渲染──│  GPU 写入 │
  │ Buffer   │           │           │
  └──────────┘           └──────────┘

  Vsync 时：交换 Front Buffer 和 Back Buffer
  问题：如果 GPU 渲染超过 16.67ms，Back Buffer 还在被写入
        → 无法交换 → 丢帧
```

#### 三缓冲（Triple Buffering）

```
  ┌──────────┐  ← 显示中（Front Buffer）
  ├──────────┤  ← 已提交（等待 Vsync 交换）
  ├──────────┤  ← GPU 正在渲染（Back Buffer）
  └──────────┘

  优点：GPU 渲染完成即可提交到第二个 buffer
       不阻塞渲染管线
  缺点：增加一帧的延迟（从 16.67ms 变为 33.33ms）
```

iOS 默认使用**双缓冲 + Vsync**。CoreAnimation 负责管理 buffer 的同步。

### 7.3 帧同步时序

```
理想情况（60fps，无卡顿）：
  ▶ Vsync（T=0ms）：App 开始准备第 1 帧
  │  CPU：解码、布局、CATransaction commit
  │  GPU：渲染、写入 Framebuffer
  │  ✓ 在 16.67ms 内完成
  ▶ Vsync（T=16.67ms）：交换 Buffer，显示第 1 帧
  │  CPU：开始准备第 2 帧

丢帧情况：
  ▶ Vsync（T=0ms）：App 开始准备第 1 帧
  │  CPU：主线程卡顿（大图解码 30ms）
  ▶ Vsync（T=16.67ms）：第 1 帧未就绪
  │  上一帧重复显示（掉帧）
  │  GPU 在 T=30ms 才完成渲染
  ▶ Vsync（T=33.33ms）：显示第 1 帧
  │  第 2 帧也推迟
  │  连续丢帧 → 视觉卡顿
```

### 7.4 CADisplayLink — 帧同步回调

```objc
// CADisplayLink 与 Vsync 同步触发
CADisplayLink *link = [CADisplayLink displayLinkWithTarget:self
                                                  selector:@selector(frameCallback:)];
link.preferredFramesPerSecond = 60; // 或 120（取决于屏幕刷新率）
[link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];

- (void)frameCallback:(CADisplayLink *)link {
    // 每个 Vsync 信号触发一次
    // 可以在这里检查帧时间，判断是否有卡顿
    CFTimeInterval duration = link.duration; // 每帧间隔
    CFTimeInterval timestamp = link.timestamp; // 当前帧时间戳
}

// 检测卡顿
// 如果 callback 的间隔 > duration × 1.2，说明发生了丢帧
```

### 7.5 60fps vs 120fps

| 维度 | 60Hz 屏幕 | 120Hz ProMotion |
|------|----------|----------------|
| 每帧预算 | 16.67ms | 8.33ms |
| 流畅度 | 标准 | 更流畅 |
| 功耗 | 低 | 高（GPU 翻倍工作） |
| 触发条件 | 始终 | 系统根据需要动态切换 |
| 代码适配 | 无需额外工作 | 默认兼容，但需注意帧预算减半 |

---

## 八、完整时序图

### 8.1 图片显示的全链路时序

```
时间轴（毫秒）
│
├── 0 ~ 5ms   ▶ 子线程图片解码（CPU）
│   JPEG → Bitmap → CGImageRef
│
├── 5 ~ 6ms   ▶ 主线程设置 UIImageView.image
│   layer.contents = CGImageRef
│   当前 RunLoop transaction 被标记为脏
│
├── 6 ~ 8ms   ▶ 主线程 RunLoop 进入 BeforeWaiting
│   → CATransaction commit
│   → Layer Tree → Presentation Tree → Render Tree
│   → 通过 XPC 发送到 Render Server
│
├── 8 ~ 12ms  ▶ Render Server（backboardd）处理
│   解析 Render Tree
│   生成 Metal / OpenGL ES 绘制指令
│   纹理上传（将位图数据 DMA 到 GPU 显存）
│
├── 12 ~ 15ms ▶ GPU 渲染管线
│   顶点着色器 → 光栅化 → 片段着色器
│   逐像素写入 Framebuffer
│
├── 16.67ms   ▶ Vsync 信号
│   Buffer 交换
│   图片显示在屏幕上 ✨
└──
```

### 8.2 各阶段耗时参考

| 阶段 | 典型耗时 | 瓶颈风险 |
|------|---------|---------|
| 图片解码（子线程） | 2-30ms（取决于图片大小） | 主线程解码时卡死 |
| CALayer 赋值 | < 0.1ms | 几乎无影响 |
| CATransaction commit | 1-5ms（取决于 Layer 复杂度） | 复杂层级时变慢 |
| XPC 通信 | 0.5-1ms | 几乎无影响 |
| 纹理上传 | 1-10ms（取决于位图大小） | 大图（48MB）上传慢 |
| GPU 渲染 | 1-8ms | 离屏渲染、复杂叠加层 |
| Vsync 等待 | 0-16.67ms | 无法避免，受上一帧完成时间影响 |

---

## 九、性能优化总结

### 9.1 减少 CPU 负担

| 优化 | 方案 | 效果 |
|------|------|------|
| **子线程解码** | dispatch_async 解码图片 | 主线程不卡顿 |
| **降采样** | CGImageSourceCreateThumbnailAtIndex | 内存从 48MB → 160KB |
| **避免 drawRect:** | 用 CALayer 替代 | UIView 的 drawRect: 是 CPU 渲染 |
| **减少 Layout** | Auto Layout 改为 Frame | 减少 CALayout 耗时 |
| **减少 CATransaction 提交次数** | 批量修改属性 | 一次提交 = 一次渲染 |

### 9.2 减少 GPU 负担

| 优化 | 方案 | 效果 |
|------|------|------|
| **减少离屏渲染** | 用 shadowPath 替代 shadow | 避免 GPU 上下文切换 |
| **合并透明图层** | opaque = YES | 减少 alpha 混合计算 |
| **减少 Overdraw** | 避免视图重叠 | 减少 GPU 重复绘制 |
| **图片尺寸匹配** | 图片尺寸 ≈ View 尺寸 x screenScale | 避免纹理缩放 |
| **使用预渲染纹理** | shouldRasterize = YES | 离屏渲染一次，后续复用 |

### 9.3 利用 RunLoop 优化

```objc
// 滚动时不加载图片，滚动停止后再加载
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // 滚动过程中不处理大量图片
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    // 滚动停止后，开始加载可见 cell 的图片
    [self loadVisibleImages];
}

// 将低优先级任务放到 DefaultMode（不影响滚动）
dispatch_async(dispatch_get_main_queue(), ^{
    // 低优先级图片预加载
    [self preloadNextPageImages];
});
// 上述 dispatch 默认在 DefaultMode，滚动时（TrackingMode）不会执行

// 或使用 RunLoop Mode 控制
[self performSelector:@selector(preloadImages)
           withObject:nil
           afterDelay:0
              inModes:@[NSDefaultRunLoopMode]];
```

---

## 十、iOS 任务处理机制

图片显示到屏幕的每一步都依赖于 iOS 的任务调度系统。这一节系统梳理 iOS 如何处理 CPU 任务、GPU 任务，以及各层级缓冲区之间的协同。

### 10.1 CPU 任务调度

#### 10.1.1 GCD 与 Quality of Service (QoS)

iOS 使用 Grand Central Dispatch (GCD) 管理线程和队列。每个任务都有 QoS 等级，系统根据 QoS 分配 CPU 时间片、功耗预算和 I/O 优先级：

| QoS | 级别 | 使用场景 | CPU 时间片 | I/O 优先级 |
|-----|------|---------|-----------|-----------|
| **userInteractive** | 最高 | UI 渲染、手势事件、动画 | 最多 | 最高 |
| **userInitiated** | 高 | 用户等待的结果（解码、加载） | 多 | 高 |
| **default** | 中 | 介于 userInitiated 和 utility 之间 | 中 | 中 |
| **utility** | 低 | 用户不直接等待的任务（同步、预加载） | 少 | 低 |
| **background** | 最低 | 后台清理、数据备份 | 极少 | 最低，限制网络 |

```objc
// iOS 如何调度不同 QoS 的任务
dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
    // 高优先级：图片解码，系统会分配更多 CPU 时间
    // 如果系统资源紧张，低 QoS 任务会被暂停，让给高 QoS
});

dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), ^{
    // 低优先级：磁盘缓存清理，只在 CPU 空闲时执行
});
```

**QoS 优先级反转**：高 QoS 任务在等待低 QoS 任务的结果（如锁）时，系统会暂时提升低 QoS 任务到高 QoS，防止优先级反转导致的死锁。

```
时间轴：
  Thread A（userInteractive）：等待 Thread B 释放锁 → 阻塞
  Thread B（background）：持有锁但 CPU 时间片少 → 慢

  系统检测到优先级反转 → 临时将 Thread B 提升为 userInteractive
  Thread B 快速执行完毕 → 释放锁 → Thread A 继续
  Thread B 恢复为 background
```

#### 10.1.2 线程池管理

iOS 的 GCD 线程池是一个**动态线程池**：

```
┌─────────────────────────────────────────────────────────────────┐
│                      GCD 线程池（动态）                            │
│                                                                  │
│  线程数量由系统动态决定，不是固定的：                               │
│    - 最低：1（主线程）                                            │
│    - 最高：取决于 CPU 核心数 × 系数（ARM64 通常 64-128）           │
│    - 系统监控 CPU 使用率、功耗、温度动态调整                        │
│                                                                  │
│  当大量并发任务时：                                                │
│    1. 系统创建新线程（但有限制）                                    │
│    2. 超过线程上限时 → 任务在队列中等待                              │
│    3. 线程数过多 → 上下文切换开销增加 → 性能反而下降                  │
│    4. 称为"线程爆炸"（Thread Explosion）→ 应避免                     │
└─────────────────────────────────────────────────────────────────┘
```

**线程爆炸问题**：

```objc
// ❌ 错误：并发创建太多线程
for (int i = 0; i < 1000; i++) {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // 1000 个线程 → 线程爆炸 → 上下文切换开销 > 实际计算
    });
}

// ✅ 正确：使用 DispatchQueue 控制并发数
dispatch_semaphore_t sem = dispatch_semaphore_create(6); // 最多 6 个并发
for (int i = 0; i < 1000; i++) {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
        // 任务
        dispatch_semaphore_signal(sem);
    });
}

// ✅ 或者使用 NSOperationQueue
NSOperationQueue *queue = [[NSOperationQueue alloc] init];
queue.maxConcurrentOperationCount = 6; // 明确限制
```

#### 10.1.3 RunLoop 的任务分发模型

RunLoop 本身不是一个线程，而是线程上的一个**事件循环机制**。iOS 中任务的执行可以被 RunLoop 分配到不同时机：

```
RunLoop 一次循环中的任务执行顺序：

┌────────────────────────────────────────────────────────┐
│  ① Source 事件处理                                      │
│     触摸事件、performSelector、端口事件                   │
│     这是大部分图片加载任务触发的地方                       │
│                                                         │
│  ② Timer 事件处理                                       │
│     NSTimer、CADisplayLink 回调                          │
│     CADisplayLink 在这里触发 Vsync 同步处理              │
│                                                         │
│  ③ BeforeWaiting（关键时机）                             │
│     CATransaction commit → Layer 提交到 Render Server    │
│     AutoReleasePool 释放                                │
│                                                         │
│  ④ 休眠（Wait）                                         │
│     等待新的事件或 Vsync 信号                            │
│                                                         │
│  ⑤ 唤醒（Wake）                                         │
│     接收到新的事件，进入下一轮循环                         │
└────────────────────────────────────────────────────────┘
```

**RunLoop 的 Observer 机制**：

```objc
// 通过 RunLoop Observer 可以监控 RunLoop 处理任务的耗时
- (void)addRunLoopObserver {
    CFRunLoopObserverRef observer = CFRunLoopObserverCreateWithHandler(
        kCFAllocatorDefault,
        kCFRunLoopAllActivities,        // 监听所有状态
        YES,
        0,
        ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
            switch (activity) {
                case kCFRunLoopEntry:
                    NSLog(@"RunLoop 进入");
                    break;
                case kCFRunLoopBeforeTimers:
                    NSLog(@"开始处理 Timer");
                    break;
                case kCFRunLoopBeforeSources:
                    NSLog(@"开始处理 Source");
                    break;
                case kCFRunLoopBeforeWaiting:
                    NSLog(@"即将休眠（CATransaction 在这里提交）");
                    break;
                case kCFRunLoopAfterWaiting:
                    NSLog(@"被唤醒");
                    break;
                case kCFRunLoopExit:
                    NSLog(@"RunLoop 退出");
                    break;
                default:
                    break;
            }
        });
    CFRunLoopAddObserver(CFRunLoopGetMain(), observer, kCFRunLoopCommonModes);
}
```

#### 10.1.4 协程与任务切换开销

```
iOS 中不同任务的切换开销对比：

  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐
  │ 函数调用      │     │ 系统调用      │     │ 线程切换      │
  │ ~5ns         │     │ ~200ns-1μs   │     │ ~1-10μs      │
  │ 用户态→用户态│     │ 用户态→内核态 │     │ 上下文完全切换 │
  └──────────────┘     └──────────────┘     └──────────────┘

  频繁的线程切换会消耗大量 CPU 时间在"切换"而非"计算"上。
  优化思路：
    • 避免过多并发线程（超过 CPU 核心数 2-3 倍即可）
    • 使用异步 I/O 替代阻塞 I/O（避免线程等待）
    • 使用 DispatchWorkItem 的优先级控制，而非创建新线程
```

### 10.2 GPU 任务调度

#### 10.2.1 Metal 命令处理架构

iOS 的 GPU 操作通过 Metal 或 OpenGL ES 进行调度。Metal 是 Apple 的底层图形 API：

```
App 进程（CPU 侧）                           GPU 侧
┌──────────────────────┐              ┌──────────────────────┐
│  Metal Command       │  提交命令     │  GPU Command         │
│  Queue               │ ───────────▶ │  Processor            │
│  (命令队列，App 写入)  │              │  (命令处理器，GPU 读取) │
│                      │              │                      │
│  ├── Command Buffer 1│              │  按时间戳顺序执行      │
│  ├── Command Buffer 2│              │  顶点着色器 → 片段    │
│  └── Command Buffer 3│              │  → 写入 Framebuffer   │
└──────────────────────┘              └──────────────────────┘
                                          │
                                          ▼
                                    ┌──────────────┐
                                    │ Framebuffer   │
                                    │ (GPU 显存)    │
                                    └──────────────┘
```

**Command Buffer 的生命周期**：

```metal
// Metal 命令缓冲区状态机
// Scheduled（已提交） → Committed（已入队） → Executing（执行中） → Completed（完成）
//                                                                    ↕
//                                                               Error（失败）

// CPU 和 GPU 通过 Command Buffer 的 Completion Handler 同步
[commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
    // GPU 完成渲染后触发
    // === 这里可以安全回收 CPU 侧资源了 ===
    // 因为 GPU 已经读完了纹理数据
    free(textureData);
}];
```

#### 10.2.2 GPU 时间片与并行

```
GPU 任务调度特点：

  1. 并行执行：
     一个 GPU 包含成百上千个着色器核心（ALU）
     可以同时处理多个像素/顶点
     称为 SIMD（Single Instruction, Multiple Data）

  2. 时间片轮转：
     多个 App 的 GPU 任务通过时间片轮转
     Render Server 负责公平调度
     前台 App 分配更多时间片

  3. 延迟隐藏：
     GPU 通过"切换 Warp/Wavefront"隐藏内存访问延迟
     当一个 warp 等待纹理采样时，GPU 切换到另一个 warp
     不需要 CPU 那种复杂的上下文切换

  4. 功耗控制：
     GPU 是 iOS 中功耗最高的组件之一
     系统根据帧率需求动态调整 GPU 频率
     降频策略：60fps → 45fps → 30fps
```

```
GPU 并行性能示例：

  一张 4000×3000 的图片需要计算 12,000,000 个像素
  每个像素需要执行片段着色器 ~100 条指令

  CPU（8 核）：12000000 × 100 / 8 = 150,000,000 指令/核
  GPU（256 核）：12000000 / 256 = 46875 像素/核
              每个像素 100 条指令 → 4,687,500 指令/核

  对于这种大量重复计算的任务，GPU 比 CPU 快 10-100 倍。
```

#### 10.2.3 GPU 驱动的渲染线程

iOS 的 Render Server 维护一个**独立的渲染线程**（在 backboardd 进程中）：

```
App 主线程                            Render Server 线程            GPU
  │                                      │                       │
  │  CATransaction commit                 │                       │
  │ ─────────────────────────────────────▶│                       │
  │                                      │                       │
  │                                      │  解析 Render Tree      │
  │                                      │  → Metal 指令          │
  │                                      │                       │
  │                                      │  Encode Command Buffer │
  │                                      │ ──────────────────────▶│
  │                                      │                       │
  │                                      │                       │ 渲染帧
  │                                      │                       │
  │                                      │  Completion Handler    │
  │                                      │ ◀──────────────────────│
  │                                      │                       │
  │  CATransaction completion block      │                       │
  │ ◀────────────────────────────────────│                       │
```

**关键点**：App 主线程提交 CATransaction 后不等待 GPU 完成，立即返回处理下一帧事件。GPU 渲染是**异步**的。App 主线程的卡顿和 GPU 的卡顿是独立的——主线程掉帧可能是因为事件处理时间太长，GPU 掉帧可能是因为渲染太复杂。

### 10.3 缓冲区（Buffer）管理

#### 10.3.1 缓冲区体系总览

```
┌─────────────────────────────────────────────────────────────────┐
│                    iOS 缓冲区体系                                 │
│                                                                  │
│  App 进程（CPU 可访问）              GPU 进程（GPU 可访问）         │
│  ┌──────────────────┐             ┌──────────────────┐           │
│  │ 对象内存（Heap）  │             │ 帧缓冲区          │           │
│  │ 图片位图数据      │             │ (Framebuffer)     │           │
│  │ ~48MB/张         │             │    │              │           │
│  └──────────────────┘             │    ├─ Front       │           │
│         │                         │    ├─ Back        │           │
│         │ DMA 上传                 │    └─ (三缓冲时第三)│           │
│         ▼                         ├──────────────────┤           │
│  ┌──────────────────┐             │ 纹理缓冲区        │           │
│  │ I/O 缓冲区        │             │ (Texture Buffer)  │           │
│  │ 磁盘→内存读缓存    │             │ 上传后的纹理数据   │           │
│  │ 文件读写缓冲       │             └──────────────────┘           │
│  └──────────────────┘             ┌──────────────────┐           │
│  ┌──────────────────┐             │ 顶点缓冲区        │           │
│  │ 网络缓冲区        │             │ (Vertex Buffer)   │           │
│  │ TCP/IP 接收缓存   │             │ 顶点坐标/颜色/UV  │           │
│  └──────────────────┘             └──────────────────┘           │
│                                                                  │
│  ┌──────────────────┐             ┌──────────────────┐           │
│  | 自动释放池缓冲    │             │ 深度/模板缓冲区   │           │
│  | (AutoReleasePool)│             │ (Z-buffer)       │           │
│  └──────────────────┘             └──────────────────┘           │
└─────────────────────────────────────────────────────────────────┘
```

#### 10.3.2 内存缓冲区

| 缓冲区类型 | 作用 | 大小 | 管理方式 |
|-----------|------|------|---------|
| **Heap（堆）** | 所有 OC 对象分配在堆上 | 动态 | ARC 引用计数 |
| **Stack（栈）** | 局部变量、函数参数 | 每线程 8MB | 自动出栈释放 |
| **AutoReleasePool** | 延迟释放临时对象 | 动态 | RunLoop 每次循环 drain |
| **Page Cache** | 文件系统缓存 | 动态 | 内核管理，LRU 淘汰 |
| **VM Page** | 虚拟内存页 | 16KB/页 | 按页分配，懒加载 |

**虚拟内存与物理内存**：

```
iOS 的虚拟内存架构：

  物理内存（Physical Memory）
  ┌──────┬──────┬──────┬──────┬──────┬──────┐
  │      │      │      │      │      │      │  ← 物理页帧
  └──┬───┴──┬───┴──┬───┴──┬───┴──┬───┴──┬───┘
     │      │      │      │      │      │
     ▼      ▼      ▼      ▼      ▼      ▼
  虚拟内存页表（Page Table）
  ┌──────┬──────┬──────┬──────┬──────┬──────┐
  │ App  │ App  │ App  │ Sys  │ Sys  │ VM   │  ← 虚拟地址空间
  │ Heap │ BSS  │ Stack│ Cache│ Code │ Swap │
  └──────┴──────┴──────┴──────┴──────┴──────┘
```

**关键概念**：
- **Page Fault**：访问未在物理内存中的虚拟页面时触发，内核从磁盘加载或分配新页
- **Memory Mapping**：`mmap` 直接将文件映射到内存，节省内存（文件无需全部读入）
- **Copy-on-Write（写时复制）**：多个进程共享同一物理页，仅当某个进程写入时才复制

#### 10.3.3 帧缓冲区（Framebuffer）

```
双缓冲交换（Vsync 控制）：

  Frame 1:                         Frame 2:
  ┌─────────┐     Vsync            ┌─────────┐
  │ Front   │◀──── 显示 ────────── │ Front   │◀──── 显示
  │ 已显示   │                     │ 新渲染  │
  ├─────────┤     ────────        ├─────────┤
  │ Back    │────▶ 交换 ──────▶   │ Back    │
  │ GPU 写入│                     │ 待写入  │
  └─────────┘                     └─────────┘

  双缓冲的问题：
    如果 GPU 渲染超过 16.67ms，Back Buffer 被占用 →
    无法交换 → 重复显示旧帧 → 掉帧

  三缓冲（Triple Buffering）：
    增加一个中间缓冲区，GPU 渲染完成即可提交
    延迟增加一帧，但减少掉帧概率
```

**iOS 中的真实情况**：iOS 使用**双缓冲 + Vsync**，但 CoreAnimation 内部实现了一些优化（如提前提交、动态调整分辨率）来减少掉帧。

#### 10.3.4 I/O 缓冲区

```objc
// 磁盘读取的缓冲区管理
// 系统内部使用 Page Cache 缓存最近读过的文件内容

// 第一次读取（磁盘 I/O，慢）
NSData *data = [NSData dataWithContentsOfFile:path];
// → 系统将文件内容读入 Page Cache
// → 返回数据

// 第二次读取（Page Cache 命中，快）
NSData *data2 = [NSData dataWithContentsOfFile:path];
// → 系统直接从 Page Cache 返回，无需磁盘 I/O
// → 如果内存紧张，Page Cache 可能已被回收

// SDWebImage 实现的磁盘缓存同样利用 Page Cache
// 通过将缓存文件保留在磁盘上，利用系统 Page Cache 加速
```

#### 10.3.5 DMA（Direct Memory Access）

DMA 是 CPU、GPU、磁盘之间高效传输数据的机制：

```
传统方式（PIO，Programmed I/O）：
  CPU：从磁盘读取 → 拷贝到内存 → 拷贝到 GPU → 写入纹理
  → CPU 全程参与 → 占用大量 CPU 时间

DMA 方式：
  CPU：发起 DMA 请求 → 磁盘 ↔ 内存（DMA 控制器）→ 内存 ↔ GPU（DMA 控制器）
  → CPU 只需发起和完成两次操作 → 数据搬运不占 CPU
```

```
图片显示中的 DMA 使用场景：

  1. 磁盘缓存读取：
     CPU 发起 read() → DMA 控制器将文件数据从磁盘读入 Page Cache
     → CPU 只需要等待 DMA 完成（或使用异步 I/O 不等待）

  2. 纹理上传（CPU → GPU）：
     Metal：CPU 将纹理数据写入共享内存区域
     → DMA 控制器将数据从 CPU 内存搬到 GPU 显存
     → GPU 开始执行渲染

  ✅ DMA 的结果：CPU 可以在 DMA 传输期间处理其他任务
  ✅ 图片解码 + 纹理上传的大部分时间，CPU 都是空闲的（等待 DMA）
```

### 10.4 CPU ↔ GPU 任务协同

#### 10.4.1 同步机制

```
CPU 和 GPU 之间通过以下机制同步：

  Fence（围栏 / 屏障）：
    ┌──────┐                ┌──────┐
    │ CPU  │───命令───▶      │ GPU  │
    │      │◀───Fence ──────│      │
    └──────┘  (GPU 完成通知) └──────┘

    CPU 需要 GPU 结果时 → 等待 Fence
    GPU 需要 CPU 数据时 → 等待 Fence

  Semaphore（信号量）：
    dispatch_semaphore_t sem = dispatch_semaphore_create(3); // 最多 3 帧在途中
    // 每提交一帧：semaphore_wait
    // GPU 完成一帧：semaphore_signal
    // → 控制 CPU 不会比 GPU 快太多，防止内存堆积
```

#### 10.4.2 帧管线与 Backpressure

```
不带缓冲的串行执行（慢）：
  CPU ████████░░░░░░░░████████░░░░░░░░████████░░░░░░
  GPU ░░░░░░░░████████░░░░░░░░████████░░░░░░░░████████
  浪费：CPU 等待 GPU + GPU 等待 CPU = 大量空闲时间

带 3 帧缓冲的管线化执行（高效）：
  CPU ████████████████████████████████████████████████
  GPU ░░░█████████████████████████████████████████████
  叠加：CPU 和 GPU 同时工作

Backpressure（背压）：
  如果 CPU 提交速度超过 GPU 处理速度：
    → Command Buffer 堆积 → 内存增加 → 延迟增加
    → 需要限制 CPU 提交的帧数（In-flight frames）
    → 通常限制为 2-3 帧
```

```objc
// Metal 中的 In-flight Frame 控制
const int maxInflightBuffers = 3;
dispatch_semaphore_t inflightSem = dispatch_semaphore_create(maxInflightBuffers);

- (void)drawFrame {
    // 等待 GPU 完成至少一帧（防止提交过快）
    dispatch_semaphore_wait(inflightSem, DISPATCH_TIME_FOREVER);

    id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];

    // 在 GPU 完成时释放资源
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
        dispatch_semaphore_signal(inflightSem); // GPU 完成一帧
    }];

    [commandBuffer commit]; // 提交渲染指令
}
```

#### 10.4.3 任务优先级调度

iOS 系统中有多条并行的任务流水线：

```
高优先级（必须 16.67ms 内完成）：
  ┌─────────────────────────────────────────┐
  │ 主线程 RunLoop：事件处理 → Layout →      │
  │ CATransaction commit → Render Tree 发送  │
  └─────────────────────────────────────────┘

中优先级（几帧内完成可接受）：
  ┌─────────────────────────────────────────┐
  │ 子线程：图片解码、图片变换、缓存读写       │
  │ 不受 Vsync 限制，但应避免长时间阻塞主线程  │
  └─────────────────────────────────────────┘

低优先级（无明确截止时间）：
  ┌─────────────────────────────────────────┐
  │ 后台线程：磁盘缓存清理、预加载下一页        │
  │ 系统可以在前台任务繁忙时直接暂停这些任务     │
  └─────────────────────────────────────────┘
```

**系统级的任务调度策略**：

```
当系统检测到 CPU 或 GPU 压力时：

  轻度压力（偶尔掉帧）：
    → 增加 CPU 频率（DVFS，Dynamic Voltage and Frequency Scaling）
    → 提高 GPU 频率

  中度压力（持续掉帧）：
    → 降低后台 App 的 CPU 时间片
    → 降低后台 GPU 任务的优先级
    → 减少后台 I/O 带宽

  重度压力（过热/电量不足）：
    → 降低屏幕刷新率（120Hz → 60Hz → 30Hz）
    → App 的 CPU 时间片减半
    → 降低屏幕亮度
    → 限制网络请求并发数
    → 极端情况下发出内存警告 → 强制 App 清理缓存
```

---

## 十二、关键面试题

### 1. 图片从解码到显示在屏幕上经历了哪些步骤？

1. **图片解码（CPU 子线程）**：JPEG/PNG → Bitmap
2. **CALayer 提交（CPU 主线程）**：`layer.contents = CGImageRef`
3. **RunLoop CATransaction commit**：Layer Tree → Render Tree
4. **XPC 传输**：App 进程 → Render Server 进程（backboardd）
5. **纹理上传（GPU）**：CPU 内存 → GPU 显存
6. **GPU 渲染管线**：顶点着色器 → 光栅化 → 片段着色器 → Framebuffer
7. **Vsync 交换**：Framebuffer → 屏幕显示

### 2. 为什么在主线程解码图片会导致卡顿？

设置 `UIImageView.image = image` 时，如果图片未解码，CoreAnimation 会在渲染时通过 ImageIO 隐式解码。这个解码过程发生在主线程、CATransaction commit 阶段（第 3 步），如果解码一张大图（48MB）需要 20-30ms，超过 16.67ms 的帧预算，就会导致丢帧。

### 3. RunLoop 和 CoreAnimation 的关系是什么？

RunLoop 在每个循环中处理事件，当事件处理完毕进入 `BeforeWaiting` 状态时，会对当前 RunLoop 中标记为"脏"的 CATransaction 执行 commit 操作。也就是说，RunLoop 是 CoreAnimation 事务的**触发者**——没有 RunLoop 的事件循环，CATransaction 就不会自动提交，Layer 的修改就不会渲染到屏幕上。

### 4. 离屏渲染是什么？什么情况下触发？

离屏渲染是指 GPU 在当前屏幕缓冲区外另开缓冲区进行渲染，需要**两次渲染 + 一次上下文切换**。

触发条件：
- `cornerRadius + masksToBounds`
- `shadow*`（阴影）
- `shouldRasterize = YES`
- `mask`（遮罩）
- `allowsGroupOpacity = YES`

### 5. iOS 为什么采用双缓冲 + Vsync？

双缓冲 + Vsync 的目的是**防止画面撕裂（Tearing）**。如果不加 Vsync，GPU 可以在任意时刻写入 Framebuffer，显示器可能在读取同一帧数据时，上半部分是新帧、下半部分是旧帧，导致视觉上的撕裂。Vsync 强制在垂直消隐期（无画面变化）切换 Buffer，保证显示要么是完整的上一帧，要么是完整的下一帧。

### 6. CPU 渲染和 GPU 渲染有什么区别？

CPU 渲染适合复杂、自定义的绘制（如文字、PDF），并行度低、功耗高。GPU 渲染适合大量简单的重复绘制（如图片、动画），并行度高、功耗低。系统默认使用 GPU 渲染（CoreAnimation），但 `drawRect:` 会触发 CPU 渲染（生成 bitmap 后仍会传给 GPU 显示）。

### 7. 为什么 iOS 用两个进程来渲染？

- **安全性**：App 崩溃不影响屏幕显示
- **性能**：Render Server 有独立的 GPU 时间片
- **隔离**：App 不能直接操作 GPU
- **统一管理**：系统可以协调跨 App 的动画和渲染（如转场动画）

### 8. iOS 中的三棵树分别是什么？

- **Layer Tree（模型树）**：存储 Layer 的所有属性，App 可直接修改
- **Presentation Tree（展示树）**：存储当前屏幕实际显示的状态，受动画影响
- **Render Tree（渲染树）**：扁平化的渲染指令集，由 Render Server 解析

### 9. CADisplayLink 和 NSTimer 有什么区别？

| 维度 | CADisplayLink | NSTimer |
|------|--------------|---------|
| **触发时机** | Vsync 信号到达时 | 设定的时间间隔到达时 |
| **触发频率** | 与屏幕刷新率同步（60Hz/120Hz） | 取决于 Timer 设定 |
| **准确性** | 与 Vsync 同步，不受 RunLoop 阻塞影响 | 受 RunLoop Mode 影响，阻塞时会暂停 |
| **用途** | 动画渲染、帧率检测 | 定时任务、延迟执行 |
| **优先级** | 高于 NSTimer | 低于 CADisplayLink |

### 10. 一张 4000×3000 的图片在 100×100 的 UIImageView 中显示，内存占用是多少？

取决于解码方式：

- **不降采样，全量解码**：4000 × 3000 × 4 = **48MB**（完整位图）
- **降采样到 View 尺寸（@3x）**：300 × 300 × 4 = **360KB**
- 如果使用 `CGImageSourceCreateThumbnailAtIndex` 降采样，不会先全量解码，直接得到目标尺寸的位图，内存就是 360KB。

因此合理的做法是始终降采样到目标显示尺寸，避免 48MB 的内存浪费。

### 11. iOS 的 GCD QoS 等级有哪些？分别用于什么场景？

| QoS | 场景 | CPU 分配 |
|-----|------|---------|
| **userInteractive** | UI 渲染、手势事件 | 最多 |
| **userInitiated** | 用户等待的结果（解码、加载） | 多 |
| **default** | 默认 | 中 |
| **utility** | 用户不直接等待的任务（同步、预加载） | 少 |
| **background** | 后台清理、备份 | 极少 |

### 12. 什么是线程爆炸？如何避免？

当大量并发任务被提交到 GCD 并发队列时，系统会创建大量线程。线程数超过 CPU 核心数 2-3 倍后，上下文切换开销超过计算收益，性能反而下降。

**避免方法**：
- 使用 `NSOperationQueue` 设置 `maxConcurrentOperationCount`
- 使用 `dispatch_semaphore` 控制并发数
- 使用 `DispatchGroup` 批量管理
- 使用 `DispatchWorkItem` 控制优先级

### 13. CPU 和 GPU 如何同步？

通过 **Fence（围栏）** 和 **Semaphore（信号量）** 同步：

- Fence：CPU 等待 GPU 完成渲染后回收资源
- Semaphore：限制 CPU 提交的 In-flight 帧数（通常 2-3 帧）
- Metal 的 `addCompletedHandler:` 在 GPU 完成时回调
- 这种操作称为 Backpressure（背压控制）

### 14. iOS 的双缓冲和三缓冲有什么区别？

| 维度 | 双缓冲 | 三缓冲 |
|------|--------|--------|
| 缓冲区数量 | Front + Back | Front + Middle + Back |
| 延迟 | 1 帧（16.67ms） | 2 帧（33.33ms） |
| 掉帧概率 | GPU 超过 16.67ms 即掉帧 | GPU 超过 33.33ms 才掉帧 |
| iOS 默认 | ✅ | ❌（某些情况自动启用） |

### 15. 什么是 DMA？在图片显示中如何应用？

DMA（Direct Memory Access）让数据在磁盘、内存、GPU 之间传输时不经过 CPU：

- **磁盘 → 内存**：系统调用 read() → DMA 控制器将文件数据读入 Page Cache
- **内存 → GPU**：Metal 将纹理数据通过 DMA 上传到 GPU 显存
- **效果**：CPU 在 DMA 传输期间可以处理其他任务，传输本身几乎不占 CPU

---

## 参考

- [Apple - Core Animation Programming Guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreAnimation_guide/Introduction/Introduction.html)
- [Apple - iOS Display Technologies](https://developer.apple.com/videos/play/wwdc2012/523/)
- [WWDC 2014 - Advanced Graphics and Animations for iOS Apps](https://developer.apple.com/videos/play/wwdc2014/419/)
- [iOS 图形渲染原理](https://juejin.cn/post/6844904179912417293)
- [关于 iOS 离屏渲染的深入研究](https://juejin.cn/post/6844903472248053774)
