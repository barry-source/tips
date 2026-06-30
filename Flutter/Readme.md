
# Flutter

## Dart基础

[Flutter](https://flutter.dev)

[Dart语言教程](https://dart.cn/guides/language)

## Flutter框架

[Flutter官方文档](https://docs.flutter.dev)

[Flutter实战](https://book.flutterchina.club/)

## Widget

- [Widget目录](https://docs.flutter.dev/reference/widgets)
- [StatefulWidget 与 StatelessWidget](https://docs.flutter.dev/ui/interactivity)
- [布局Widget](https://docs.flutter.dev/ui/widgets/layout)

### Widget 对比

#### 1. LimitedBox vs ConstrainedBox

两者都用于约束子 widget 的大小，但行为和适用场景有本质区别。

| 维度 | ConstrainedBox | LimitedBox |
|------|---------------|------------|
| **约束类型** | 强约束（强制应用） | 弱约束（仅当无约束时生效） |
| **优先级** | 覆盖父级约束 | 仅在父级无约束时采用 |
| **超过父约束** | ❌ 不能超过父级 max 约束 | ✅ 不会超过父级已有约束 |
| **适用场景** | 需要固定的最小/最大尺寸 | 需要默认值但不想限制父级布局 |
| **典型用途** | 限定卡片最大宽度 | ListView 中给无界项提供默认高度 |

**ConstrainedBox**：对子 widget 施加**额外的约束**，会覆盖父级的约束。

```dart
ConstrainedBox(
  constraints: BoxConstraints(
    minWidth: 100,
    maxWidth: 200,
    minHeight: 50,
    maxHeight: 100,
  ),
  child: Container(color: Colors.red),
)
// → 子 widget 的大小被限制在 100-200 × 50-100 范围内
// → 即使父级给了更大的空间，也不会超过 200×100
```

**LimitedBox**：仅在父级对该方向**未提供约束**时才有作用。父级已有明确约束时，LimitedBox 被忽略。

```dart
// 场景：ListView 中的 item，ListView 在主轴方向是无约束的（无限高）
ListView.builder(
  itemBuilder: (context, index) {
    return LimitedBox(
      maxHeight: 100,  // 仅在父级无约束时生效
      child: Container(color: Colors.blue),
    );
  },
)
// → ListView 的高度方向是无限的，LimitedBox 生效，限制每项最高 100
// → 如果放在 Column 中（有固定高度），LimitedBox 被忽略，使用父级约束
```

```dart
// 对比效果：
// ConstrainedBox：即使父级给了 500×500 的空间，也强制子 widget 不超过 200×100
ConstrainedBox(
  constraints: BoxConstraints(maxWidth: 200, maxHeight: 100),
  child: Container(width: 500, height: 500, color: Colors.red),
)
// → 实际大小：200×100（被强制缩小）

// LimitedBox：父级有约束时不生效，子 widget 仍为 500×500
LimitedBox(
  maxWidth: 200,
  maxHeight: 100,
  child: Container(width: 500, height: 500, color: Colors.blue),
)
// → 实际大小：500×500（LimitedBox 被忽略）
// → 如果父级无约束，则限制为 200×100
```

**对比总结**：

| 场景 | ConstrainedBox | LimitedBox |
|------|---------------|------------|
| 限制 Container 最大宽度 300 | ✅ 即使父级更大，也强制 300 | ❌ 父级有约束时无效 |
| ListView 每项默认高度 80 | ❌ 会限制 ListView 布局 | ✅ 主轴无约束时生效 |
| Column 中限制子组件高度 | ✅ 强制应用 | ❌ Column 有约束时不生效 |
| 想要"除非父级说了算，否则给个默认值" | ❌ 总是覆盖 | ✅ 仅在无约束时兜底 |

**记忆口诀**：
- **ConstrainedBox** = 强制约束（**C**onstrained = **C**ompulsory）
- **LimitedBox** = 兜底约束（仅在父级"撒手不管"时生效）

---

#### 2. Flexible vs Expanded

两者都用于 `Row`、`Column` 或 `Flex` 中分配剩余空间，`Expanded` 是 `Flexible` 的特殊情况。

| 维度 | Flexible | Expanded |
|------|----------|----------|
| **本质** | 通用 flex 组件 | Flexible 的子类，fit 固定为 tight |
| **是否强制填满** | ❌ 不一定（取决于 fit） | ✅ 强制子 widget 填满分配空间 |
| **fit 参数** | `FlexFit.loose`（默认）或 `FlexFit.tight` | 固定为 `FlexFit.tight` |
| **子 widget 自身大小** | ✅ 保持自身大小（loose 时） | ❌ 被子 widget 自身大小覆盖 |
| **适用场景** | 分配空间但子 widget 可能更小 | 强制子 widget 撑满分配空间 |

```dart
// Expanded = Flexible with fit: FlexFit.tight
// 以下两者等价：
Expanded(child: Container(color: Colors.red))
Flexible(
  fit: FlexFit.tight,
  child: Container(color: Colors.red),
)
```

**关键区别演示**：

```dart
Row(
  children: [
    Flexible(
      fit: FlexFit.loose,  // loose：子 widget 可以不填满
      child: Container(
        width: 50,         // 即使分配了更多空间，子 widget 只占 50
        height: 50,
        color: Colors.red,
      ),
    ),
    Expanded(
      child: Container(
        width: 50,         // ❌ 无效：Expanded 强制撑满，width 被忽略
        height: 50,
        color: Colors.blue,
      ),
    ),
  ],
)
// 红色区域：50px（保持自身大小）
// 蓝色区域：撑满剩余空间（width: 50 被忽略）
```

```dart
// 实际布局效果示意：
// ┌─────────────────────────────┐
// │ Row                         │
// │ ┌──────┬────────────────────┐│
// │ │  红  │       蓝           ││
// │ │  50  │    撑满剩余空间     ││
// │ └──────┴────────────────────┘│
// └─────────────────────────────┘
```

**何时用哪个？**

| 场景 | 推荐 | 原因 |
|------|------|------|
| 平分 Row/Column 空间 | `Expanded` | 每个子元素等宽，强制撑满 |
| 子 widget 有固定大小，不想被拉长 | `Flexible.loose` | 保持子 widget 原始尺寸 |
| 分配剩余空间，但子 widget 可能有最大尺寸限制 | `Flexible.tight`（等价于 Expanded） | 等同于 Expanded |
| 多个子 widget 按比例分配 | `Flexible` + `flex` 参数 | `flex: 2` 比 `flex: 1` 多一倍空间 |

```dart
// 按比例分配空间
Row(
  children: [
    Flexible(
      flex: 2,    // 占 2/3
      child: Container(color: Colors.red),
    ),
    Flexible(
      flex: 1,    // 占 1/3
      child: Container(color: Colors.blue),
    ),
  ],
)
```

**记忆口诀**：
- **Expanded** = 扩张填满（**E**xpanded = **E**xhaust）
- **Flexible** = 灵活分配（子 widget 可以"不听话"）

---

#### 3. 如何在 Row 中避免内容溢出屏幕？

Row 的默认行为：所有子 widget 的宽度之和超过屏幕宽度时，会触发 `overflowed` 错误，右侧内容被截断。

```
┌──────────────────────────────┐
│ Row                          │
│ ┌────┬────┬────┬────┬────┬─╌╌│ ← 溢出！右侧裁剪
│ │ 1  │ 2  │ 3  │ 4  │ 5  │...│
│ └────┴────┴────┴────┴────┴─╌╌│
└──────────────────────────────┘
```

**方案一：用 Expanded / Flexible 包裹（按比例缩放）**

```dart
// 每个子项按比例分配空间，不会溢出
Row(
  children: [
    Expanded(child: Text('长文本内容...')),
    Expanded(child: Icon(Icons.star)),
    Expanded(child: Icon(Icons.delete)),
  ],
)
```
✅ 适合：子项可以等分或按比例分空间

**方案二：用 SingleChildScrollView 包裹（可滚动）**

```dart
SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: Row(
    children: [
      // 任意数量的子 widget，超出屏幕可以左右滑动
      for (var i = 0; i < 20; i++)
        Chip(label: Text('Item $i')),
    ],
  ),
)
```
✅ 适合：子项数量动态、需要全部保留可访问
❌ 缺点：需要横向滑动，不够直观

**方案三：用 Flexible 控制文本省略（文本溢出专用）**

```dart
Row(
  children: [
    Icon(Icons.person),
    const SizedBox(width: 8),
    Flexible(
      child: Text(
        '这是一段很长的文本内容可能会溢出屏幕',
        overflow: TextOverflow.ellipsis,  // 超出部分显示...
        maxLines: 1,
      ),
    ),
    Icon(Icons.arrow_forward),
  ],
)
```
✅ 适合：图标 + 文本 + 图标的常见布局
✅ 效果：文本溢出时显示 `...`，不撑破 Row

**方案四：用 FittedBox 缩放（自动缩小）**

`FittedBox` 直接包裹子 widget，如果子 widget 超出可用空间，自动等比缩小：

```dart
FittedBox(
  fit: BoxFit.scaleDown,  // 超出时自动缩小
  child: Row(
    children: [
      Text('很长很长很长的文本内容'),
      Text('的文本'),
    ],
  ),
)
```

⚠️ **注意**：`FittedBox` 需要放在**有明确宽度约束**的父级中（如 Column、Center、Scaffold body）。如果放在 `Row` 内，`Row` 会给它无限宽度导致溢出，此时需用 `Expanded` 包裹。

✅ 适合：子 widget 可以等比缩小
❌ 缺点：文本过小可能看不清

**方案五：用 Wrap 替代 Row（自动换行）**

```dart
Wrap(
  children: [
    Chip(label: Text('Tag 1')),
    Chip(label: Text('Tag 2')),
    Chip(label: Text('Tag 3 Very Long')),
    // 一行放不下时自动换到下一行
  ],
)
```
✅ 适合：标签列表、选项组等可以换行的场景
❌ 不适合：必须单行排列的场景

**方案选择总结**：

| 场景 | 推荐方案 | 原因 |
|------|---------|------|
| 子项数量固定，可等分 | `Expanded` | 简单高效 |
| 图标+文本+图标 | `Flexible` + `TextOverflow.ellipsis` | 文本溢出优雅处理 |
| 子项数量动态，需全部可访问 | `SingleChildScrollView` + `Row` | 横向滚动查看所有 |
| 子项可以缩小 | `FittedBox` + `BoxFit.scaleDown` | 自动等比缩放 |
| 子项可以换行 | `Wrap` 替代 `Row` | 自动换行不溢出 |

---

#### 4. ListView 中嵌套 Column 怎么让其不报错？

**问题原因**：

```
ListView 给 child 的约束：主轴方向高度 = ∞（可滚动）
Column 的默认行为：尝试撑满主轴方向
→ Column 收到 ∞ 高度后无法确定自身大小 → 报错！
```

```
❌ 报错代码：
ListView(
  children: [
    Column(                // ← 收到 ∞ 高度，无法确定大小
      children: [
        Text('Item 1'),
        Text('Item 2'),
      ],
    ),
  ],
)
// 错误：Vertical viewport was given unbounded height.
```

**方案一：不嵌套，直接用 ListView 的 children（推荐）**

```dart
// Column 中的每一项直接作为 ListView 的 child
ListView(
  children: [
    Text('Item 1'),
    Text('Item 2'),
    Text('Item 3'),
    // 不需要 Column 包裹，ListView 本身就是垂直列表
  ],
)
```
✅ 最简单，性能最好
✅ 推荐做法

**方案二：Column 设置固定高度**

```dart
ListView(
  children: [
    Container(
      height: 100,  // 给 Column 一个明确的高度
      child: Column(
        children: [
          Text('Header'),
          Text('Subtitle'),
        ],
      ),
    ),
    // 后面的 item 正常滚动
    Text('Item 2'),
  ],
)
```
✅ 适合：Column 内容高度确定的场景

**方案三：Column 用 IntrinsicHeight 撑满（不推荐）**

```dart
ListView(
  children: [
    IntrinsicHeight(
      child: Column(
        children: [
          Text('Item 1'),
          Text('Item 2'),
        ],
      ),
    ),
  ],
)
```
⚠️ `IntrinsicHeight` 会执行两次布局，性能开销大
⚠️ 仅适合子项数量极少的情况

**方案四：Column 用 ShrinkWrap 包裹（不推荐）**

```dart
Column(
  mainAxisSize: MainAxisSize.min,  // 收缩到子 widget 大小，不撑满
  children: [
    Text('Item 1'),
    Text('Item 2'),
  ],
)
```
⚠️ `mainAxisSize: MainAxisSize.min` 让 Column 不尝试撑满
⚠️ 但 Column 本身没有滚动能力，内容过多时可能溢出

**最佳实践**：

| 场景 | 推荐 |
|------|------|
| Column 内容不多 | 直接把子 widget 展开为 ListView 的 children |
| Column 需要独立高度 | 用 `Container(height:)` 固定高度 |
| Column 内容动态变化 | 用 `SingleChildScrollView` + `Column` 替代 |
| Column 需要独立滚动 | 用 `NestedScrollView` 或 `SliverList` |

---

#### 5. LayoutBuilder vs MediaQuery

两者都用于获取布局信息，但获取时机和粒度不同。

| 维度 | LayoutBuilder | MediaQuery |
|------|-------------|------------|
| **获取时机** | 构建阶段（build 时） | 任意阶段（build + 非 build） |
| **数据来源** | 父级 widget 的实际约束 | 整个应用的 MediaQuery 数据 |
| **粒度** | 当前 widget 的约束（精准） | 屏幕级别（较粗） |
| **是否可响应父级变化** | ✅ 父级边界变化即触发重建 | ❌ 只能响应屏幕级别的变化 |
| **访问方式** | `builder` 回调参数 | `MediaQuery.of(context)` |
| **典型用途** | 根据可用空间动态布局 | 获取屏幕尺寸、系统字体、安全区域 |

**MediaQuery 使用**：

```dart
@override
Widget build(BuildContext context) {
  // 获取屏幕信息
  final mediaQuery = MediaQuery.of(context);
  final screenWidth = mediaQuery.size.width;
  final screenHeight = mediaQuery.size.height;
  final isLandscape = mediaQuery.orientation == Orientation.landscape;
  final safePadding = mediaQuery.padding.top;  // 状态栏高度
  final bottomSafe = mediaQuery.padding.bottom; // 底部安全区

  // 响应式：根据屏幕宽度返回不同布局
  if (screenWidth > 600) {
    return _buildWideLayout();
  } else {
    return _buildNarrowLayout();
  }
}
```

**LayoutBuilder 使用**：

```dart
@override
Widget build(BuildContext context) {
  return LayoutBuilder(
    builder: (context, constraints) {
      // constraints 来自父级给的约束
      final maxWidth = constraints.maxWidth;
      final maxHeight = constraints.maxHeight;

      // 根据实际可用空间决定布局
      if (maxWidth > 600) {
        return _buildWideLayout();
      } else {
        return _buildNarrowLayout();
      }
    },
  );
}
```

**关键区别：相同代码不同结果**：

```dart
// 放在宽度为 300 的 Container 中 ↓
Center(
  child: Container(
    width: 300,
    child: Column(
      children: [
        // MediaQuery：永远是屏幕宽度（如 375），不是 300
        Text('${MediaQuery.of(context).size.width}'),   // 375

        // LayoutBuilder：实际父级约束宽度 300
        LayoutBuilder(
          builder: (_, c) => Text('${c.maxWidth}'),     // 300
        ),
      ],
    ),
  ),
)
```

**何时用哪个？**

| 场景 | 推荐 | 原因 |
|------|------|------|
| 需要知道屏幕物理尺寸 | `MediaQuery` | 直接获取屏幕信息 |
| 需要根据父级可用空间布局 | `LayoutBuilder` | 父级约束而非屏幕 |
| 获取系统状态栏/安全区域 | `MediaQuery.of(context).padding` | MediaQuery 独有 |
| 响应式布局（手机 vs 平板） | `LayoutBuilder` | 不一定是满屏，可能是分屏 |
| 需要知道设备方向 | `MediaQuery.of(context).orientation` | MediaQuery 独有 |
| 获取字体缩放比例 | `MediaQuery.of(context).textScaleFactor` | MediaQuery 独有 |
| Container 内部根据剩余空间动态调整 | `LayoutBuilder` | 精准反映父级约束 |

**记忆口诀**：
- **MediaQuery** = 问屏幕（全局信息：尺寸、安全区、字体）
- **LayoutBuilder** = 问父级（局部信息：实际给了多少空间）

---

#### 6. Navigator.of(context) vs Navigator.push vs GlobalKey\<NavigatorState\>

三者都能实现页面跳转，但获取 Navigator 的方式不同。

| 维度 | Navigator.of(context) | Navigator.push | GlobalKey\<NavigatorState\> |
|------|----------------------|---------------|---------------------------|
| **获取方式** | 从 Widget 树向上查找最近的 NavigatorState | 语法糖，内部调 `.of(context)` | 直接持有 NavigatorState 引用 |
| **是否需要 context** | ✅ 需要 | ✅ 需要 | ❌ 不需要 |
| **能否 rootNavigator** | ✅ `rootNavigator: true` | ❌ 不能指定 | ✅ 自己控制哪个 key |
| **多 Navigator 场景** | ✅ 找到最近的 | ❌ 只能根 Navigator | ✅ 精确指定 |
| **能否在 BLoC/Service 中使用** | ❌ 需要 context | ❌ 需要 context | ✅ 无需 context |
| **时机要求** | Widget 树构建后 | Widget 树构建后 | 任意时机（包括 initState 前） |

**实质关系**：

```dart
// Navigator.push 的源码本质就是调用了 Navigator.of(context)
static Future<T?> push<T extends Object?>(BuildContext context, Route<T> route) {
  return Navigator.of(context).push(route);  // 内部实现
}
```

**多 Navigator 嵌套场景的区别**：

```dart
// 场景：App 中有两个 Navigator
// 根 Navigator（App 层）+ 内层 Navigator（Tab 页内部）

// ❌ Navigator.push：永远推到根 Navigator
Navigator.push(context, route);
// → 跳转到根导航栈，覆盖整个 App

// ✅ Navigator.of(context)：找到最近的 Navigator
// 如果 context 在内层 Navigator 中，就推到内层栈
Navigator.of(context).push(route);
// → 跳转到内层导航栈，只在当前 Tab 内切换

// ✅ 如果确实想推到根 Navigator
Navigator.of(context, rootNavigator: true).push(route);
// → 强制推到根导航栈
```

**代码示例**：

```dart
// 普通页面跳转（两者效果一样）
onPressed: () {
  // 方式一
  Navigator.push(context, MaterialPageRoute(
    builder: (_) => SecondPage(),
  ));

  // 方式二（等价）
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => SecondPage(),
  ));
}

// 弹出 Dialog（必须用 .of(context) 找 NavigatorState）
showDialog(
  context: context,
  builder: (_) => AlertDialog(title: Text('Dialog')),
);
// showDialog 内部调用的是 Navigator.of(context, rootNavigator: true)

// Tab 内页导航（必须用 .of(context) 保证在内层栈）
Navigator.of(context).push(MaterialPageRoute(
  builder: (_) => TabInnerPage(),
));

// GlobalKey<NavigatorState> 使用：无需 context
final navigatorKey = GlobalKey<NavigatorState>();

MaterialApp(
  navigatorKey: navigatorKey,       // 绑定到根 Navigator
  home: HomePage(),
);

// 在任何地方跳转（BLoC、Service、Dart 文件）
navigatorKey.currentState?.push(
  MaterialPageRoute(builder: (_) => SecondPage()),
);

// 也可以使用 key 精确控制多个 Navigator
final innerNavigatorKey = GlobalKey<NavigatorState>();

// 在 Widget 树中绑定
Navigator(
  key: innerNavigatorKey,
  onGenerateRoute: ...,
);

// 只操作内层导航
innerNavigatorKey.currentState?.push(...);
```

**GlobalKey\<NavigatorState\> 的使用场景**：

```dart
// 场景 1：在 BLoC/Provider/Service 中导航
class AuthService {
  final GlobalKey<NavigatorState> navigatorKey;

  void logout() {
    navigatorKey.currentState?.pushReplacementNamed('/login');
  }
}

// 场景 2：SnackBar 弹出到最上层
navigatorKey.currentState?.context;  // 获取 Navigator 的 context
ScaffoldMessenger.of(navigatorKey.currentState!.context)
  .showSnackBar(SnackBar(content: Text('提示信息')));

// 场景 3：不依赖 BuildContext 的全局导航
class GlobalNavigator {
  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();

  static Future<T?> push<T>(Widget page) {
    return key.currentState?.push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  static void pop<T>([T? result]) {
    key.currentState?.pop(result);
  }
}

// 在 main.dart 中传入
MaterialApp(navigatorKey: GlobalNavigator.key, ...)

// 任意地方调用
GlobalNavigator.push(SecondPage());
```

**最佳实践总结**：

| 场景 | 推荐 | 原因 |
|------|------|------|
| 简单 App，Widget 树中导航 | `Navigator.push` | 最简洁 |
| 嵌套 Navigator（Tab + 内页） | `Navigator.of(context)` | 确保在内层栈 |
| 推到根栈（全屏覆盖/Dialog） | `Navigator.of(context, rootNavigator: true)` | 强制根 Navigator |
| BLoC/Service 中导航 | `GlobalKey<NavigatorState>` | 无需 context |
| 全局导航（SnackBar/通知跳转） | `GlobalKey<NavigatorState>` | 不依赖 Widget 树 |
| UI 组件内部 | `Navigator.of(context)` | 标准做法 |

**总结**：`Navigator.of(context)` 更灵活，可以指定 `rootNavigator`；`Navigator.push` 更简洁，本质是前者的语法糖。在多 Navigator 嵌套场景中必须用 `Navigator.of(context)`。

---

#### 7. Navigator 1.0 与 Navigator 2.0 的区别

| 维度 | Navigator 1.0 | Navigator 2.0 |
|------|---------------|---------------|
| **核心 API** | `Navigator.push` / `pop`（命令式） | `Navigator` + `Router` + `RouteInformationParser`（声明式） |
| **路由声明方式** | 在 `MaterialApp.routes` 中静态声明 | 用 `Router` widget 构建，代码完全控制 |
| **页面栈控制** | 隐式栈管理，系统管理路由栈 | 显式栈管理，开发者完全控制页面列表 |
| **URL/深度链接** | ❌ 不支持（需要第三方库） | ✅ 原生支持，通过 `RouteInformationParser` |
| **Web 支持** | ❌ 地址栏与页面状态不同步 | ✅ 地址栏与页面状态完全同步 |
| **状态恢复** | 依赖系统自动恢复 | 开发者完全控制恢复逻辑 |
| **测试性** | 有限（路由栈在内部，不易断言） | 好（页面列表是普通 List，可任意断言） |
| **学习成本** | 低 | 高（需要理解 Router/Parser/Delegate 概念） |
| **适用场景** | 简单 App、Tab 导航 | 复杂导航（Web、深度链接、多窗口） |

**Navigator 1.0（命令式导航）**：

```dart
// 在 MaterialApp 中声明路由
MaterialApp(
  routes: {
    '/': (context) => HomePage(),
    '/detail': (context) => DetailPage(),
  },
)

// 命令式跳转
Navigator.pushNamed(context, '/detail');
Navigator.push(context, MaterialPageRoute(builder: (_) => DetailPage()));

// 传参
Navigator.pushNamed(context, '/detail', arguments: {'id': 42});

// 返回
Navigator.pop(context);
Navigator.pop(context, result);
```

**Navigator 2.0（声明式导航）**：

```dart
// 1. 定义路由配置
class AppRoute {
  final String path;
  final Map<String, String> params;
  AppRoute.home() : path = '/', params = {};
  AppRoute.detail(int id) : path = '/detail', params = {'id': '$id'};
}

// 2. RouteInformationParser（解析 URL）
class AppRouteParser extends RouteInformationParser<AppRoute> {
  @override
  Future<AppRoute> parseRouteInformation(
    RouteInformation information,
  ) async {
    final uri = Uri.parse(information.location ?? '/');
    if (uri.path == '/detail') {
      return AppRoute.detail(int.parse(uri.queryParameters['id'] ?? '0'));
    }
    return AppRoute.home();
  }

  @override
  RouteInformation restoreRouteInformation(AppRoute route) {
    return RouteInformation(location: route.path);
  }
}

// 3. RouterDelegate（管理页面栈）
class AppRouterDelegate extends RouterDelegate<AppRoute>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin {

  AppRoute _currentRoute = AppRoute.home();
  List<MaterialPage> _pages = [];

  @override
  Widget build(BuildContext context) {
    _pages = [
      MaterialPage(child: HomePage(
        onDetail: (id) {
          _currentRoute = AppRoute.detail(id);
          notifyListeners();
        },
      )),
    ];
    if (_currentRoute.path == '/detail') {
      _pages.add(MaterialPage(child: DetailPage(id: _currentRoute.params['id']!)));
    }
    return Navigator(
      pages: _pages,           // 显式声明页面栈
      onPopPage: (route, result) {
        if (!route.didPop(result)) return false;
        _currentRoute = AppRoute.home();
        notifyListeners();
        return true;
      },
    );
  }

  @override
  Future<void> setNewRoutePath(AppRoute route) async {
    _currentRoute = route;
  }
}

// 4. 使用
MaterialApp.router(
  routeInformationParser: AppRouteParser(),
  routerDelegate: AppRouterDelegate(),
);
```

**对比代码量**：

| 功能 | Navigator 1.0 | Navigator 2.0 |
|------|---------------|---------------|
| 简单页面跳转 | 1 行 | 100+ 行（Parser + Delegate） |
| 深度链接支持 | 需要插件 | 原生内置 |
| Web 地址栏同步 | 不支持 | 自动同步 |
| 页面栈完全控制 | 不支持 | 原生支持 |

**何时升级到 Navigator 2.0？**

```
你的 App 需要什么？
        │
        ├── 简单的 Tab 导航 + push/pop → Navigator 1.0 ✅
        │
        ├── Web 支持 / URL 链接 → Navigator 2.0 ✅
        │
        ├── 深度链接 / 通知跳转 → Navigator 2.0 ✅
        │
        ├── 复杂的页面栈控制 → Navigator 2.0 ✅
        │
        └── 以上都不需要 → Navigator 1.0 完全够用 ✅
```

**第三方桥接方案**：如果不想手写 Navigator 2.0 的样板代码，可使用社区方案：

| 库 | 特点 |
|------|------|
| **go_router** | Flutter 官方推荐，基于 Navigator 2.0 封装，声明式路由 |
| **auto_route** | 代码生成，类型安全，支持 DI |
| **beamer** | 基于 Navigator 2.0，配置简单 |

---

#### 8. Flutter 中各种 Key 的区别

Key 用于在 Widget 树重建时标识和匹配 widget。Flutter 中有 5 种 Key：

| Key 类型 | 构造方式 | 比较依据 | 唯一性要求 | 适用场景 |
|----------|---------|---------|-----------|---------|
| **ValueKey** | `ValueKey(value)` | value 的 `==` 和 `hashCode` | 同一层级需唯一 | 单个字段唯一标识（如 id） |
| **ObjectKey** | `ObjectKey(obj)` | 对象引用的 `==` 和 `hashCode` | 同一层级需唯一 | 用对象本身作为标识 |
| **UniqueKey** | `UniqueKey()` | 每次创建都是唯一值 | 永远唯一 | 强制 widget 重建 |
| **PageStorageKey** | `PageStorageKey(value)` | value 的 `==` | 全局需唯一 | 保存页面滚动位置 |
| **GlobalKey** | `GlobalKey()` | 全局唯一标识 | 全局必须唯一 | 访问 widget 状态、跨组件通信 |

**Key 的作用场景**：区分 widget 树中的元素，避免状态错乱。

```dart
// ❌ 没有 Key：状态错乱
Column(
  children: [
    TextField(),  // 用户输入 "A"
    TextField(),  // 用户输入 "B"
  ],
)
// 交换顺序后：
Column(
  children: [
    TextField(),  // 显示的是 "A"（错：应该是空的）
    TextField(),  // 显示的是 "B"（错：应该也是空的）
  ],
)
// Flutter 按位置匹配，不会重建，TextEditingController 被复用

// ✅ 加上 Key：正确重建
Column(
  children: [
    TextField(key: ValueKey('first')),  // 输入 "A"
    TextField(key: ValueKey('second')), // 输入 "B"
  ],
)
// 交换顺序后：
Column(
  children: [
    TextField(key: ValueKey('second')), // ✅ 空的，新创建
    TextField(key: ValueKey('first')),  // ✅ 空的，新创建
  ],
)
// Flutter 按 Key 匹配，找不到对应 Key 就重建
```

**ValueKey**：最常用，适合用 id、index 等唯一值标识：

```dart
// 列表项用 id 作为 Key
ListView.builder(
  itemBuilder: (_, index) {
    final item = items[index];
    return ListTile(
      key: ValueKey(item.id),  // 用数据 id，不随 index 变化
      title: Text(item.title),
    );
  },
)
// 好处：数据删除或插入时，其他 item 不会因 index 变化而重建
```

**ObjectKey**：适合用复杂对象作为标识：

```dart
// 用联系人对象本身作为标识
ListView(
  children: contacts.map((contact) =>
    ContactCard(key: ObjectKey(contact))
  ).toList(),
)
```

**UniqueKey**：每次创建都不同，强制 widget 重建：

```dart
// 强制某个 widget 重新初始化
// 比如：每次用户点"重置"时，表单完全重建
_FormWidget(key: UniqueKey())

// 或强制重新加载图片（重置图片加载状态）
Image.network(
  url,
  key: UniqueKey(),  // 再次进入时强制重新加载
)
```

**PageStorageKey**：保存页面在列表中的滚动位置：

```dart
// 切换 Tab 后恢复滚动位置
ListView(
  key: PageStorageKey('home_list'),
  children: [...],
)

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: TabBarView(
      children: [
        ListView(key: PageStorageKey('tab1'), ...),
        ListView(key: PageStorageKey('tab2'), ...),
      ],
    ),
  );
}
// 切换 Tab 时滚动位置自动保存和恢复
```

**GlobalKey**：全局唯一，可访问 widget 的 State：

```dart
// 1️⃣ 访问子 widget 的 State
final formKey = GlobalKey<FormState>();

Form(
  key: formKey,
  child: Column(
    children: [
      TextFormField(validator: ...),
      ElevatedButton(
        onPressed: () {
          // 通过 GlobalKey 获取 Form 的 State
          if (formKey.currentState!.validate()) {
            formKey.currentState!.save();
          }
        },
        child: Text('Submit'),
      ),
    ],
  ),
)

// 2️⃣ 跨组件获取 widget 位置和尺寸
final containerKey = GlobalKey();

@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final renderBox = containerKey.currentContext?.findRenderObject() as RenderBox?;
    final size = renderBox?.size;        // widget 的尺寸
    final position = renderBox?.localToGlobal(Offset.zero);  // 屏幕坐标
  });
}

// 3️⃣ 全局导航（详见第 6 条）
final navigatorKey = GlobalKey<NavigatorState>();
MaterialApp(navigatorKey: navigatorKey, ...);
```

**Key 的选择原则**：

```
是否需要跨组件访问 State 或 context？
  ├── 是 → GlobalKey（但只在必要时使用，有额外开销）
  └── 否 → 是否需要持久化滚动位置？
       ├── 是 → PageStorageKey
       └── 否 → 数据源用什么标识唯一的？
            ├── 字符串/id → ValueKey
            ├── 复杂对象 → ObjectKey
            └── 强制重建 → UniqueKey
```

**GlobalKey 的注意事项**：

```
GlobalKey 有额外开销：
  - 每个 GlobalKey 在 Element 树中全局注册
  - 持有 BuildContext 引用，可能阻止垃圾回收
  - 如果大量使用，考虑用 ValueKey 替代

最佳实践：
  - Form 校验 → ✅ 用 GlobalKey
  - 导航 → ✅ 用 GlobalKey
  - 列表 item → ❌ 用 ValueKey（性能更好）
  - 动画过渡 → ❌ 用 ValueKey（GlobalKey 破坏动画效果）
``` 