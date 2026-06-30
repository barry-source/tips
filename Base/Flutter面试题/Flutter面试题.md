# Flutter 面试题整理

来源：https://juejin.cn/post/7067828374344826887

---

### 1. Dart 语法中 dynamic、var、object 三者的区别

| 关键字 | 类型推断 | 赋值后可改变类型 | 编译时类型检查 |
|--------|---------|----------------|---------------|
| `var` | ✅ 由初始值推断 | ❌ 一旦赋值类型固定 | ✅ 严格检查 |
| `dynamic` | ❌ 不推断 | ✅ 可以 | ❌ 不做检查 |
| `Object` | ❌ 不推断 | ✅ 可以 | ✅ 只能调 Object 方法 |

```dart
var a = 'hello';      // 推断为 String
// a = 123;            // ❌ 编译错误，类型已固定

dynamic b = 'hello';
b = 123;               // ✅
b.nonexistentMethod(); // ✅ 编译通过，运行时报错

Object c = 'hello';
// c.length;            // ❌ 编译错误
(c as String).length;   // ✅ 需强转
```

**核心区别**：
- `var` 是语法糖，实际类型由编译器推断，一旦确定不可变
- `dynamic` 完全绕过编译检查，运行时确定，灵活但危险
- `Object` 是类型系统的根，不能调子类特有方法

---

### 2. const 和 final 的区别

**相同点**：均不可重新赋值，必须初始化。

**不同点**：

| 维度 | const | final |
|------|-------|-------|
| 赋值时机 | **编译时**确定值 | **运行时**确定值 |
| 修饰实例变量 | ❌ 不可以 | ✅ 可以 |
| 类中使用 | 需 `static const` | 直接 `final` |
| List 可变性 | **深度不可变**，不可修改元素 | **引用不可变**，元素可修改 |
| 构造函数 | ✅ 常量构造函数 | ❌ 不可 |
| const 构造函数的要求 | 所有成员必须是 `final` | — |

```dart
// 本质区别
final now = DateTime.now();  // ✅ 运行时确定
// const now = DateTime.now(); // ❌ 编译错误

// const 深度不可变
const list = [1, 2, 3];
// list.add(4);  // ❌ 编译错误

final list2 = [1, 2, 3];
list2.add(4);    // ✅ 可以
```

---

### 3. Dart 中 ?? 与 ??= 的区别

| 运算符 | 含义 | 示例 |
|--------|------|------|
| `A ?? B` | A 为空返回 B，否则返回 A | `name ?? 'Guest'` |
| `A ??= B` | A 为空时把 B 赋值给 A | `name ??= 'Alice'` |

```dart
String? name;
print(name ?? 'Guest');   // Guest
name ??= 'Alice';
print(name);              // Alice
```

---

### 4. 什么是 Flutter 里的 Key？有什么用？

Key 是 Widgets、Elements、SemanticsNodes 的标识符，用于在 Widget 树重建时识别和复用。

**层级结构**：
```
Key（抽象类）
├── LocalKey（本地唯一，同层对比）
│   ├── ValueKey       ← 按值比较，最常用（如 id）
│   ├── ObjectKey      ← 按对象引用比较
│   ├── UniqueKey      ← 每次都唯一，强制重建
│   └── PageStorageKey ← 保存滚动位置
└── GlobalKey（全局唯一，可访问 State）
```

**作用**：修改集合中元素的顺序或数量时，用 Key 保持状态复用，防止状态错乱。

---

### 5. Flutter 中的 GlobalKey 是什么，有什么作用

GlobalKey 是**全局唯一**的 Key，可以通过它获取对应 Widget 的 State 对象，实现跨组件访问。

**典型用途**：

```dart
// 1️⃣ 表单校验
final formKey = GlobalKey<FormState>();
Form(key: formKey, child: ...);
formKey.currentState?.validate();

// 2️⃣ 获取 Widget 位置/尺寸
final key = GlobalKey();
RenderBox? box = key.currentContext?.findRenderObject() as RenderBox?;
var size = box?.size;
var position = box?.localToGlobal(Offset.zero);

// 3️⃣ 全局导航（无需 context）
final navKey = GlobalKey<NavigatorState>();
MaterialApp(navigatorKey: navKey);
navKey.currentState?.pushNamed('/detail');

// 4️⃣ 跨组件访问状态
final childKey = GlobalKey<ChildWidgetState>();
ChildWidget(key: childKey);
childKey.currentState?.someMethod();
```

---

### 6. main() 和 runApp() 的作用分别是什么？有什么关系？

```dart
void main() {
  runApp(MyApp());  // main 中调用 runApp
}
```

| 函数 | 作用 |
|------|------|
| `main()` | 程序入口，Dart VM 启动后第一个执行的函数 |
| `runApp()` | 将根 Widget 渲染到屏幕上，绑定 Widget 树和 Render 树 |

**关系**：`runApp()` 在 `main()` 中被调用。`main()` 是入口，`runApp()` 启动 Flutter 渲染引擎。

---

### 7. 什么是 Widget？Flutter 里有几种类型的 Widget？生命周期？

Widget 是 Flutter 中 UI 组件的**描述**（不可变的配置文件）。

**两种类型**：

#### StatelessWidget（无状态）
```dart
// 生命周期：构造函数 → build()
class MyWidget extends StatelessWidget {
  const MyWidget({super.key});
  @override
  Widget build(BuildContext context) {
    return Text('Hello');
  }
}
```

#### StatefulWidget（有状态）
```dart
// 完整生命周期（按调用顺序）：
① Widget 构造函数
② createState()            → 创建 State 对象
③ State 构造方法
④ initState()              → 只调用一次，必须 super.initState()
⑤ didChangeDependencies()  → initState 后立即调用 / InheritedWidget 变化时
⑥ build()                  → 每次 setState() 都会触发重建
———（用户交互触发 setState）———
⑦ setState()               → 标记需要重建，触发 build()
⑧ deactivate()             → Widget 从树中移除（push/pop 都可能触发）
⑨ dispose()                → 永久销毁，自己的逻辑在 super.dispose() 之前
```

---

### 8. 简单说一下 Flutter 里 async 和 await？

```dart
Future<void> fetchData() async {
  print('开始请求');           // 同步执行
  final data = await httpGet(); // 暂停，不阻塞线程
  print('请求完成: $data');    // 异步调度执行
}
```

**关键点**：
- `async` 标记函数为异步，返回值自动包装为 `Future`
- `await` 是暂停点（suspension point），**不阻塞线程**
- `await` 之前的代码同步执行，之后的代码调度为异步
- 一个 `async` 函数可以有 0 个或多个 `await`

---

### 9. Future 和 Stream 有什么不一样？

| 维度 | Future | Stream |
|------|--------|--------|
| **数据量** | 单个异步结果 | 连续的数据序列 |
| **订阅方式** | `.then()` / `await` | `.listen()` / `await for` |
| **多次监听** | ❌ 不支持 | ✅ 广播流支持 |
| **错误处理** | `.catchError()` | `.handleError()` |
| **典型场景** | 网络请求、文件读取 | 用户输入、网络监听、定时器 |

```dart
// Future：一次异步操作
Future<String> fetchData() async => 'data';

// Stream：连续异步事件
Stream.periodic(Duration(seconds: 1), (i) => i)
  .take(5)
  .listen(print);
```

---

### 10. Flutter 中 Widget、Element、RenderObject、Layer 的关系

```
Widget（配置蓝图，immutable）
  │  inflate（填充）
  ▼
Element（树中的实体，管理生命周期）
  │  持有和操作
  ├── RenderObject（布局 + 绘制）
  └── Layer（合成场景）
```

**各对象职责**：

| 对象 | 职责 | 可变性 |
|------|------|--------|
| **Widget** | 存储渲染配置，描述 UI | ❌ 不可变（immutable） |
| **Element** | 树中的实体，管理 Widget 和子 Element 的生命周期 | ✅ 可变 |
| **RenderObject** | 布局（layout）和绘制（paint）的实际执行者 | ✅ 可变 |
| **Layer** | 合成多个 RenderObject 的绘制结果 | ✅ 可变 |

**关键原理**：
- Widget 只是配置，**可以被多个 Element 引用**（同一 Widget inflate 多次）
- Widget 变化时 Element **不会重建**，只是更新持有的 Widget 引用
- RenderObject 负责实际的测量和绘制

---

### 11. 简述 State 的生命周期

| 方法 | 调用时机 | 次数 | 必调 super |
|------|---------|------|-----------|
| `initState()` | Widget 创建后立即调用 | **仅一次** | ✅ 最先调用 |
| `didChangeDependencies()` | initState 后 / InheritedWidget 变化时 | 多次 | ✅ |
| `build()` | 每次需要渲染（setState / 父重建） | 多次 | ❌ |
| `didUpdateWidget()` | 父 Widget 重建且 runtimeType 不变时 | 多次 | ✅ |
| `setState()` | 手动触发，标记为脏需要重建 | 多次 | ❌ |
| `deactivate()` | Widget 从树中暂时移除 | 多次 | ✅ |
| `dispose()` | Widget 永久销毁 | **仅一次** | ✅ 最后调用 |

**调用顺序**：
```
initState → didChangeDependencies → build
  → (用户交互) → setState → build
  → (页面退出) → deactivate → dispose
```

---

### 12. 简述 Flutter 中自定义 View 流程

**方式一：组合（Widget composition）**
继承或组合已有 Widget，通过嵌套构建 UI。适用于大多数场景。

**方式二：自定义绘制（CustomPainter）**
当需要完全自定义图形时使用 Canvas 绘制：

```dart
class CirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(50, 50), 30, paint);
  }

  @override
  bool shouldRepaint(CirclePainter oldDelegate) => false;
}

// 使用
CustomPaint(painter: CirclePainter(), size: Size(100, 100));
```

**两种方式的对比**：

| 维度 | 组合 | 自定义绘制 |
|------|------|-----------|
| 复杂度 | 低 | 高 |
| 灵活性 | 受限于现有 Widget | 完全自由 |
| 性能 | 好 | 需注意 shouldRepaint |
| 适用场景 | 标准 UI 布局 | 图表、图形、特殊效果 |

---

### 13. flutter_boost 的优缺点，内部实现

FlutterBoost 是阿里闲鱼团队开源的 Flutter/Native 混合开发框架。

**核心原理**：

**1. 引擎复用** — 整个 App 只创建一个 Flutter Engine 实例，每个 Flutter 页面封装为一个 Native 容器（Android: Activity / iOS: ViewController），容器与 Flutter 页面一一绑定，通过消息驱动同步生命周期。

**2. 统一路由栈** — Flutter 页面和 Native 页面统一在原生导航栈中管理，每个容器分配唯一 ID，跳转时根据栈顶页面类型动态切换。

**3. 生命周期同步** — 原生容器生命周期（onCreate/onResume/onDestroy）通过 PlatformChannel 同步到 Flutter Widget 生命周期。

**4. 通信机制** — 基于 `MethodChannel` 双向通信，回调通过唯一 ID 缓存。

**优点**：
- ✅ 性能好：单引擎复用，避免多引擎内存泄漏
- ✅ 路由统一：Flutter 和 Native 页面统一栈管理
- ✅ 生命周期自动同步
- ✅ 闲鱼亿级用户生产验证

**缺点**：
- ❌ 学习成本高，需同时掌握 Flutter 和 Native
- ❌ 依赖原生路由，现有框架需额外适配
- ❌ 多 Tab 场景需手动处理页面状态缓存
- ❌ 需与 Flutter SDK 版本严格匹配

**适用场景**：已有成熟 Native 项目，渐进式迁移到 Flutter，且对页面切换性能敏感。

---

### 14. Flutter 的渲染机制

**渲染管线**（6 个阶段）：

```
Vsync 信号
  │
  ▼
① UI 线程（Dart）：构建 Widget Tree → Element Tree → RenderObject Tree
  │
  ▼
② 布局（Layout）：计算每个 RenderObject 的大小和位置
  │
  ▼
③ 绘制（Paint）：生成 Layer 树（绘制指令）
  │
  ▼
④ GPU 线程：图层合成（Compositing）
  │
  ▼
⑤ Skia 引擎：栅格化（Rasterization）
  │
  ▼
⑥ OpenGL / Vulkan：提交到 GPU → 屏幕显示
```

**关键特点**：
- Flutter 拥有**自研渲染引擎**，不依赖平台 UI 组件
- 每一帧从 Vsync 信号开始，需在 16.67ms（60fps）内完成全部阶段
- UI 线程和 GPU 线程通过流水线并行工作

---

### 15. Flutter 和 Native 的优缺点

| 维度 | Flutter | Native（iOS/Android 原生） |
|------|---------|---------------------------|
| **跨平台** | ✅ 一套代码多端运行 | ❌ 各平台独立开发 |
| **性能** | ✅ 接近 Native（自绘引擎） | ✅ 最优 |
| **开发效率** | ✅ 热重载，一套代码 | ❌ 需分别开发 |
| **UI 一致性** | ✅ 自绘，平台差异小 | ❌ iOS 和 Android 风格不同 |
| **包体积** | ❌ 较大（含 Skia + Dart VM） | ✅ 小 |
| **第三方库** | ❌ 生态相对小 | ✅ 丰富成熟 |
| **平台能力** | ❌ 需 PlatformChannel 桥接 | ✅ 直接调用原生 API |
| **学习成本** | ❌ 需学 Dart + Flutter | ✅ 熟悉平台语言即可 |
| **动态化** | ❌ 不支持热更新（iOS） | ✅ 支持（RN/JSPatch） |

---

### 16. Flutter 支不支持 120Hz

**支持**。原理如下：

| 平台 | 机制 | 说明 |
|------|------|------|
| **iOS** | `CADisplayLink` | 自动适配 ProMotion（120Hz） |
| **Android** | `Choreographer` | 自动适配高刷屏幕 |

Flutter 的渲染管线完全由 Vsync 信号驱动，与设备刷新率无关。设备给 60Hz 就跑 60fps，给 120Hz 就跑 120fps。只需要注意帧预算减半（120Hz 时每帧只有 8.33ms）。

---

### 17. 状态管理熟悉哪些

| 方案 | 原理 | 适用规模 | 流行度 |
|------|------|---------|--------|
| **setState** | Widget 内部回调 | 🔸 简单组件 | ⭐⭐⭐⭐⭐ |
| **InheritedWidget** | 自定向下的树传递 | 🔸 全局配置 | ⭐⭐⭐ |
| **Provider** | Google 官方推荐，基于 InheritedWidget | 🔹 中大型项目 | ⭐⭐⭐⭐⭐ |
| **BLoC / Cubit** | Stream 驱动，业务逻辑分离 | 🔹 复杂业务 | ⭐⭐⭐⭐ |
| **Riverpod** | Provider 改进版，编译安全 | 🔹 中大型项目 | ⭐⭐⭐⭐ |
| **Redux / FishRedux** | 单向数据流，可预测 | 🔸 大型复杂应用 | ⭐⭐⭐ |
| **GetX** | 轻量、高性能、全家桶 | 🔸 中小型项目 | ⭐⭐⭐⭐ |
| **MobX** | 响应式编程，细粒度响应 | 🔸 需要细粒度的场景 | ⭐⭐ |

---

### 18. 多线程怎么处理

Dart 是单线程模型，通过以下方式处理"多线程"任务：

| 方式 | 本质 | 适用场景 |
|------|------|---------|
| **Future / async-await** | 事件循环调度 | I/O、网络请求 |
| **Stream** | 连续事件流 | 数据监听 |
| **Isolate** | 独立 VM 实例（真正并发） | CPU 密集型计算 |
| **compute()** | Isolate 的便捷封装 | 简单耗时任务 |

```dart
// compute() 使用
int sum(int n) {
  var total = 0;
  for (var i = 0; i < n; i++) total += i;
  return total;
}

void main() async {
  final result = await compute(sum, 1000000000);
  print(result); // 不会阻塞 UI
}
```

**关键区分**：
- `Future` 是**异步**（事件队列调度），不是**并行**
- `Isolate` 才是真正的**并发并行**（独立线程/进程）

---

### 19. Flutter 中大图片上传

四种策略：

| 策略 | 原理 | 优点 | 缺点 |
|------|------|------|------|
| **1. 降采样压缩** | 解码时缩放到目标尺寸 | 减少传输数据量 | 损失画质 |
| **2. 分片上传** | 切分为多个小片段依次上传 | 支持断点续传 | 实现复杂 |
| **3. 原生平台压缩** | 通过 PlatformChannel 调用原生 API | 压缩效率高 | 多端需分别实现 |
| **4. 后台 Isolate** | 在单独 Isolate 中处理编解码 | 不阻塞 UI | 需处理 Port 通信 |

```dart
// 降采样 + Isolate 后台处理
Future<Uint8List> compressInBackground(Uint8List data) async {
  return compute(_compressImage, data);
}

Uint8List _compressImage(Uint8List data) {
  // 在 Isolate 中执行，不影响 UI 线程
  return data; // 实际进行压缩处理
}
```

---

### 20. await for 如何使用

`await for` 用于持续监听 Stream 并处理每个事件：

```dart
Stream<int> countStream(int max) async* {
  for (var i = 0; i < max; i++) {
    await Future.delayed(Duration(seconds: 1));
    yield i;
  }
}

void main() async {
  await for (final value in countStream(5)) {
    print(value); // 每秒输出 0, 1, 2, 3, 4
  }
  print('Stream 完成');
}
```

**注意事项**：
- `await for` 会**阻塞当前函数**直到 Stream 关闭
- 如果 Stream 永远不会关闭，函数会永远挂起
- 适合有明确结束事件的 Stream（如文件读取、网络响应）

---

### 21. Stream 有两种订阅模式

| 模式 | 监听器数量 | 示例 |
|------|-----------|------|
| **单订阅流（Single）** | **只能有一个** | 文件读取、HTTP 响应 |
| **广播流（Broadcast）** | **可以有多个** | 网络状态、事件总线 |

```dart
// 单订阅流
final single = Stream.fromIterable([1, 2, 3]);
single.listen(print);
// single.listen(print);  // ❌ 只能监听一次

// 广播流
final broadcast = Stream.fromIterable([1, 2, 3]).asBroadcastStream();
broadcast.listen((d) => print('A: $d'));
broadcast.listen((d) => print('B: $d')); // ✅ 可以多次监听
```

---

### 22. Flutter build 方法中的 BuildContext 具体是什么东西

**`BuildContext` 本质就是 `Element` 的抽象接口**。

```dart
// Element 实现了 BuildContext 接口
class Element implements BuildContext { ... }
```

`BuildContext.of(context)` 的原理：
1. `context` 是某个 Widget 的 Element
2. 从这个 Element 开始**向上遍历 Element 树**
3. 找到对应的 `InheritedElement`，读取数据

```dart
// 示例：MediaQuery.of(context) 的实现原理
static MediaQueryData of(BuildContext context) {
  final widget = context.dependOnInheritedWidgetOfExactType<MediaQuery>();
  return widget!.data;
}
```

---

### 23. Flutter 打包成 Web、移动端、桌面端的过程

| 目标平台 | 编译方式 | 渲染引擎 | 产物 |
|---------|---------|---------|------|
| **Android** | AOT 编译 → 原生二进制 | Skia（Android 内置） | APK / AAB |
| **iOS** | AOT 编译 → 原生二进制 | Skia（打包在 Engine 中） | IPA |
| **Web** | Dart→JS / WebAssembly | CanvasKit / DOM | HTML + JS |
| **桌面端** | AOT 编译 → 桌面原生二进制 | Skia | EXE / DMG / AppImage |

**AOT**（Ahead-of-Time）：Dart 代码被直接编译成平台的原生机器码，运行时不需要 Dart VM 解释执行。

---

### 24. Dart 是值传递还是引用传递

**值传递**。Dart 传递的是**引用的副本**（即指针的值），而非对象本身的副本。

```dart
void modify(String s) {
  s = 'modified'; // 只改了局部引用的指向
}

void main() {
  var str = 'original';
  modify(str);
  print(str); // original（未被改变）
}
```

**注意**：如果传递的是可变对象（如 List），通过引用修改对象内容会影响原对象：

```dart
void addItem(List<int> list) {
  list.add(4); // 通过引用修改了对象内容
}

void main() {
  var list = [1, 2, 3];
  addItem(list);
  print(list); // [1, 2, 3, 4]
}
```

---

### 25. Dart 是弱引用还是强引用

**强引用**。Dart 的 GC（垃圾回收）基于可达性分析，所有默认引用都是强引用。

```dart
var obj = SomeClass();  // 强引用：GC 不会回收
obj = null;             // 引用断开，可回收
```

如需弱引用，Dart 3.0+ 提供了 `WeakReference`：

```dart
final weakRef = WeakReference(someObject);
print(weakRef.target); // 可能为 null（已被回收）
```

---

### 26. get set 方法实现

```dart
class Person {
  String _name;   // 私有属性（下划线开头）

  Person(this._name);

  // getter：像属性一样取值
  String get name => _name;

  // setter：像属性一样赋值，带校验逻辑
  set name(String value) {
    if (value.isNotEmpty) {
      _name = value;
    }
  }
}

void main() {
  var p = Person('Alice');
  print(p.name);   // 调 getter
  p.name = 'Bob';  // 调 setter
  print(p.name);   // Bob
}
```

Dart 的 getter/setter 语法让方法调用看起来像直接访问属性，实际上是调用了对应的方法。

---

### 27. Flutter 如何与原生 Android/iOS 进行通信？

通过 **PlatformChannel** 实现，有三种类型：

| Channel 类型 | 用途 | 通信方向 | 返回值 |
|-------------|------|---------|--------|
| **MethodChannel** | 方法调用（最常用） | 双向 | 一次性结果 |
| **BasicMessageChannel** | 半结构化消息 | 双向 | 持续通信 |
| **EventChannel** | 数据流 | 原生→Flutter | 持续事件 |

```dart
// Flutter 端调用
static const channel = MethodChannel('com.example/channel');
final result = await channel.invokeMethod('getBatteryLevel');

// Android 端处理
new MethodChannel(getFlutterEngine().getDartExecutor(), "com.example/channel")
  .setMethodCallHandler((call, result) {
    if (call.method == "getBatteryLevel") {
      result.success(batteryLevel);
    }
  });
```

> **注意**：PlatformChannel **不是线程安全的**，调用需在主线程。

---

### 28. 简述 Flutter 的热重载

基于 **JIT 编译**模式的代码增量同步机制。

**流程**：
```
扫描改动文件 → 增量编译（Dart→内核） → 推送更新
  → 代码合并 → Widget 重建 → 保持 State
```

**支持**（✅ 热重载生效）：
- UI 样式修改
- 方法/函数逻辑修改
- 添加或修改 Widget 结构

**不支持**（❌ 需要热重启）：
- 全局变量 / 静态属性的修改
- `main()` 函数修改
- `initState()` 中的代码修改
- 枚举和泛型的修改
- 数据结构定义的修改

---

### 29. 怎么理解 Isolate？

Isolate 是 Dart 对 **Actor 并发模式**的实现。每个 Isolate 是一个独立的执行实体，拥有：

- **独立的内存堆** — 不共享内存，无竞争条件
- **独立的事件循环** — 有自己的 MicroTask 和 Event 队列
- **独立的线程** — 在 Dart VM 中通常对应一个操作系统线程

```
Isolate A                     Isolate B
┌─────────────┐              ┌─────────────┐
│ 自己的内存   │              │ 自己的内存   │
│ 自己的事件循环│   SendPort  │ 自己的事件循环│
│ 自己的线程   │ ◄──────────► │ 自己的线程   │
└─────────────┘    消息传递   └─────────────┘
```

```dart
// 创建 Isolate
final receivePort = ReceivePort();
await Isolate.spawn(entryPoint, receivePort.sendPort);
final data = await receivePort.first;

void entryPoint(SendPort sendPort) {
  sendPort.send('Hello from isolate');
}
```

**特点**：
- 没有共享内存 → 没有锁 → 没有死锁
- 通信通过 Port 消息传递
- 创建开销较大，适合 CPU 密集型而非简单异步

---

### 30. Dart 的作用域

Dart **没有 `public` / `private` 关键字**，可见性用下划线 `_` 控制：

```dart
class Example {
  String publicField = '公开';     // 默认公开
  String _privateField = '私有';   // _ 开头 = 库内私有
}
```

**规则**：
- 默认所有成员是 **公开的**
- 以 `_` 开头的成员是**库私有**（同一文件内可访问）
- 可见性基于**库**（文件），不是基于类

---

### 31. Dart 当中的「..」表示什么意思？

**级联操作符**（Cascade notation）。在同一对象上连续调用多个方法，返回该对象本身。

```dart
// 传统写法
var list = <String>[];
list.add('a');
list.add('b');
list.remove('a');

// 级联写法
var list = <String>[]
  ..add('a')
  ..add('b')
  ..remove('a');
```

**对比**：
- `.` 调用方法并返回方法自身的返回值
- `..` 调用方法后返回原对象（相当于 `this`）

---

### 32. Dart 是不是单线程模型？是如何运行的？

Dart **是单线程模型**，通过**事件循环**（Event Loop）驱动。

**两个任务队列**：

```
执行顺序：
① 执行所有同步代码
② 清空 MicroTask Queue（微任务队列）
③ 从 Event Queue（事件队列）取一个任务执行
④ 回到 ②
```

| 队列 | 优先级 | 包含 |
|------|--------|------|
| **MicroTask Queue** | 🔴 最高 | `Future.microtask()`、`.then()` 回调 |
| **Event Queue** | 🟢 较低 | `Future()`、I/O、Timer、UI 事件 |

**关键规则**：每次从 Event Queue 取任务前，必须先**清空整个 MicroTask Queue**。

---

### 33. Dart 是如何实现多任务并行的？

通过 **Isolate** 实现。Dart 是单线程，但一个进程可以运行多个 Isolate：

| 方式 | 说明 |
|------|------|
| `Isolate.spawn()` | 在同一个 Dart VM 中创建新 Isolate |
| `Isolate.spawnUri()` | 从外部 Dart 文件创建 Isolate |
| `compute()` | Flutter 提供的便捷方法，快速在后台 Isolate 执行 |

```dart
// Isolate 通信
final receivePort = ReceivePort();
await Isolate.spawn(worker, receivePort.sendPort);

void worker(SendPort sendPort) {
  sendPort.send(heavyCalculation());
}

final result = await receivePort.first;
```

**与 Future 的区别**：
- `Future`：在**同一个线程**的事件队列中调度，不是并行
- `Isolate`：**真正的多线程并行**，各自独立执行

---

### 34. 说一下 Dart 异步编程中的 Future 关键字？

**Future** 代表一个异步操作的**最终结果**（类似 JavaScript 的 Promise）。

```dart
// 创建 Future
Future<String> fetchData() {
  return Future.delayed(
    Duration(seconds: 1),
    () => 'data',
  );
}

// 使用方式一：async/await
final data = await fetchData();

// 使用方式二：then 链式
fetchData().then((data) {
  print(data);
}).catchError((error) {
  print(error);
});
```

**Future 的状态**：
```
Uncompleted → Completed（含 data 或 error）
```

**Future 的执行优先级**：Main > MicroTask > Event Queue
（与 Q32 事件循环一致）

---

### 35. 说一下 mixin 机制？

mixin 是 Dart 2.1 引入的代码复用机制，用于解决**多重继承**问题。

**关键特征**：

| 特征 | 说明 |
|------|------|
| **构造函数** | ❌ 不能有构造函数 |
| **单继承 + 多混入** | `extends` 一次 + `with` 多次 |
| **抽象方法** | ✅ 可以有，需要混入类实现 |
| **具体实现** | ✅ 可以有 |
| **本质** | 既不是继承，也不是接口，是一种全新的复用方式 |

```dart
mixin Flyable {
  void fly() => print('Flying');
  void land();  // 抽象方法，需要混入类实现
}

mixin Swimmable {
  void swim() => print('Swimming');
}

class Duck extends Animal with Flyable, Swimmable {
  @override
  void land() => print('Landing');
  @override
  void speak() => print('Quack');
}
```

**适用场景**：当多个类需要共享同一组方法，但又不适合用继承（is-a）或接口（can-do）表达时。

---

### 36. 介绍下 Flutter 的 Framework 层和 Engine 层

**Framework 层**（Dart）：
- 使用频率最高
- 包含 Material（Android 风格）和 Cupertino（iOS 风格）UI 库
- 包含 Widgets、动画、绘制、渲染、手势识别
- 底层封装为 `dart:ui` 库

**Engine 层**（C++）：
- Skia 2D 绘图引擎（跨平台）
- 图形转换、文字渲染、位图渲染
- Dart 运行时（VM / AOT）
- 平台通道（PlatformChannel）的实现

**架构关系**：
```
Framework 层（Dart 代码）
      ↕  dart:ui 绑定
Engine 层（C++ 代码：Skia + Dart VM）
      ↕  系统调用
平台层（Android / iOS / Web）
```

---

### 37. 简述 Flutter 的线程管理模型

Flutter Engine 维护 **4 个 Task Runner**（但不由 Engine 创建，由 Embeder 提供）：

| Task Runner | 职责 | 是否阻塞 UI |
|-------------|------|------------|
| **Platform Runner** | 处理平台消息（主线程） | ❌ 不应长时间执行 |
| **UI Runner** | 运行 Dart VM、构建 Widget、执行 Layout/Paint | ⚠️ 16.67ms 限制 |
| **GPU Runner** | 图层合成，提交给 GPU | ❌ 应快速完成 |
| **IO Runner** | 图片解码、文件读取 | ✅ 可较长时间执行 |

```
         Vsync 信号
            │
            ▼
    ┌───────────────┐
    │   UI Runner    │ ← 该帧的 build + layout + paint
    └───────┬───────┘
            │
            ▼
    ┌───────────────┐
    │  GPU Runner    │ ← 合成并提交给 GPU
    └───────────────┘
```

**注意**：Flutter Engine 不直接创建线程，线程由 Embeder（中间适配层）提供和管理。

---

### 38. 介绍下 Flutter 的理念架构

Flutter 采用**三层架构**：

```
┌─────────────────────────────────────────┐
│  Framework（Dart 代码）                   │
│  ┌──────────────────────────────────┐   │
│  │ Material / Cupertino             │   │
│  │ Widgets / Animation / Gesture    │   │
│  │ Rendering / Painting             │   │
│  │ dart:ui（底层 API 绑定）           │   │
│  └──────────────────────────────────┘   │
├─────────────────────────────────────────┤
│  Engine（C++ 代码）                      │
│  ┌──────────────────────────────────┐   │
│  │ Skia（图形引擎）                   │   │
│  │ Dart VM / AOT Runtime            │   │
│  │ Platform Channel                 │   │
│  │ Text Layout（文字排版）            │   │
│  └──────────────────────────────────┘   │
├─────────────────────────────────────────┤
│  Embedder（平台适配层）                    │
│  ┌──────────────────────────────────┐   │
│  │ Thread Setup（线程管理）           │   │
│  │ Surface Setup（渲染表面）          │   │
│  │ Platform Plugins（平台插件）       │   │
│  └──────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

| 层级 | 语言 | 职责 | 使用频率 |
|------|------|------|---------|
| **Framework** | Dart | UI 组件、布局、动画 | 🔴 最高 |
| **Engine** | C++ | 渲染引擎、Dart 运行时 | 🔵 底层 |
| **Embedder** | 平台语言 | 操作系统适配 | 🟢 移植 |

---

### 39. Future 和 Isolate 有什么区别？

| 维度 | Future | Isolate |
|------|--------|---------|
| **类型** | 异步编程 | 并发编程 |
| **线程** | 同一线程，事件队列调度 | 独立线程/进程 |
| **内存** | 共享同一 Isolate 的内存 | **完全独立**，不共享 |
| **通信** | 函数返回值 / await | Port（SendPort / ReceivePort） |
| **适用** | I/O、网络请求、定时器 | CPU 密集型计算、大文件处理 |
| **创建开销** | 几乎为零 | **较大**（创建新 VM 堆） |
| **是否真正的并行** | ❌ 不是 | ✅ 是 |

```dart
// Future：不并行，只是排队
Future.delayed(Duration(seconds: 1), () => print('async'));

// Isolate：真正并行
Isolate.spawn((_) => heavyTask(), null);
```

---

### 40. 什么是 Navigator？MaterialApp 做了什么？

**Navigator**：Flutter 的页面堆栈导航器，提供 `push` / `pop` 管理页面路由。

**MaterialApp** 自动完成的事情：
1. **创建 Navigator**：管理路由栈
2. **提供 MediaQuery**：屏幕尺寸、字体缩放等
3. **提供 Theme**：主题配置
4. **提供 Route 解析**：从 `routes` 或 `onGenerateRoute` 创建页面

```dart
// MaterialApp 自动创建 Navigator
MaterialApp(
  navigatorKey: navKey,
  routes: {
    '/home': (context) => HomePage(),
    '/detail': (context) => DetailPage(),
  },
)

// 页面跳转
Navigator.pushNamed(context, '/detail');
// 本质：Navigator.of(context) 向上遍历 Element 树
// → 找到 MaterialApp 创建的 _NavigatorState
// → 调用 pushNamed 完成导航
```
