# Dart 基础

### 1. Dart 中 var、final、const 的区别是什么？

| 关键字 | 赋值时机 | 可重新赋值 | 对象本身可变 | 类型推断 |
|--------|---------|-----------|-------------|---------|
| `var` | 运行时 | ✅ 可以 | ✅ 可变 | ✅ 由初始值推断 |
| `final` | 运行时 | ❌ 不可 | ✅ 可变（引用不可变） | ✅ 由初始值推断 |
| `const` | 编译时 | ❌ 不可 | ❌ 不可变（深度不可变） | ✅ 由初始值推断 |

```dart
var name = 'Alice';      // 可重新赋值
// name = 123;            // ❌ 编译错误：name 是 String 类型

final now = DateTime.now(); // ✅ 运行时确定值
// now = DateTime.now();    // ❌ 编译错误：final 不可重新赋值

const pi = 3.14159;         // ✅ 编译时常量
// const now2 = DateTime.now(); // ❌ 编译错误：不是编译时常量

// const 的特殊性：对象深度不可变
const list = [1, 2, 3];
// list.add(4);             // ❌ 编译错误：const 列表不可变

final list2 = [1, 2, 3];
list2.add(4);               // ✅ final 引用不可变，对象本身可变
```

**使用建议**：
- 值会变 → `var`
- 值运行时确定，不会变 → `final`
- 值编译时已知的字面量 → `const`

---

### 2. late 关键字的作用是什么？

`late` 用于延迟初始化，告诉编译器"这个变量虽然声明时没有赋值，但我保证在使用前会初始化"。

**使用场景一：延迟初始化（懒加载）**

```dart
class Config {
  late String apiKey;     // 声明时不赋值，使用前必须初始化

  void init() {
    apiKey = 'secret_key';  // 第一次使用时初始化
  }

  void showKey() {
    print(apiKey);          // 如果 init() 没被调用过，这里会运行时崩溃
  }
}
```

**使用场景二：延迟初始化 + 懒计算**

```dart
class Report {
  late final String summary = _computeSummary();  // 访问时才计算，只计算一次

  String _computeSummary() {
    print('Computing summary...');
    return 'This is the summary';
  }
}

var report = Report();
print('Report created');            // Report created
print(report.summary);              // Computing summary... \n This is the summary
print(report.summary);              // This is the summary（不会重复计算）
```

**使用场景三：非空类型成员变量**

```dart
class User {
  late final String name;
  late final int age;

  User(Map<String, dynamic> json)
      : name = json['name'],
        age = json['age'];
}
```

**`late` 的陷阱**：

```dart
late String value;
print(value);  // ❌ LateInitializationError：value 尚未初始化，运行时崩溃
```

| 特性 | `late` | 直接赋值 | `late final` |
|------|--------|---------|-------------|
| 声明时赋值 | ❌ 不需要 | ✅ 需要 | ❌ 不需要 |
| 使用前必须初始化 | ✅ 必须 | ✅ 已经初始化 | ✅ 必须 |
| 是否可重新赋值 | ✅ 可 | ✅ 可 | ❌ 不可 |
| 是否懒加载 | ✅ 是 | ❌ 否 | ✅ 是（只计算一次） |
| 未初始化就访问 | ❌ 运行时崩溃 | ✅ 不会 | ❌ 运行时崩溃 |

---

### 3. mixin 与 abstract class 的区别是什么？

| 维度 | mixin | abstract class |
|------|-------|---------------|
| 能否被实例化 | ❌ 不能单独存在 | ❌ 不能 |
| 能否有构造函数 | ❌ 不能 | ✅ 可以有 |
| 能否有具体实现 | ✅ 可以 | ✅ 可以 |
| 能否有抽象方法 | ✅ 可以 | ✅ 可以 |
| 使用方式 | `with` 混入 | `extends` 继承 |
| 使用次数 | 可以混入多个 | 只能继承一个 |
| 能否被 extends | ❌ 不能 | ✅ 能 |
| 能否被 implements | ❌ 不能 | ✅ 能 |

```dart
// abstract class：可以同时定义抽象方法和具体实现，有构造函数
abstract class Animal {
  String name;
  Animal(this.name);

  void speak();                    // 抽象方法
  void breathe() {                 // 具体实现
    print('$name is breathing');
  }
}

class Dog extends Animal {
  Dog(String name) : super(name);
  @override
  void speak() => print('Woof');
}

// mixin：不能有构造函数，可以有抽象方法和具体实现
mixin Flyable {
  void fly() => print('Flying!');
}

mixin Swimmable {
  void swim() => print('Swimming!');
}

class Duck extends Animal with Flyable, Swimmable {
  Duck(String name) : super(name);
  @override
  void speak() => print('Quack');
}
```

**总结**：abstract class 适合定义"是什么"的层次关系（is-a），mixin 适合定义"能干什么"的能力组合（can-do）。

---

### 4. abstract class、extends、implements、mixin（with）的区别

| 维度 | abstract class | extends | implements | mixin（with） |
|------|---------------|---------|-----------|--------------|
| **关键字** | `abstract class` | `extends` | `implements` | `mixin` / `with` |
| **含义** | 抽象类，不能实例化 | 继承父类 | 实现接口（Dart 的每一个类都是隐式接口） | 可复用的代码片段 |
| **继承/混入数量** | — | 只能一个 | 可多个 | 可多个 |
| **是否需要重写方法** | 抽象方法必须重写 | 按需 override | 全部必须重写 | 按需 override |
| **能否有构造函数** | ✅ 可以 | — | — | ❌ 不能 |
| **能否有抽象方法** | ✅ 可以 | — | — | ✅ 可以 |
| **能否调 super** | — | ✅ 可以 | ❌ 不能 | ✅ 可以 |
| **能否被 extends** | ✅ 可以 | — | — | ❌ 不能 |
| **能否被 implements** | ✅ 可以 | — | — | ❌ 不能 |
| **场景** | 定义基类骨架 | is-a 关系 | 遵循某种规范 | 组合能力（can-do） |

```dart
// abstract class：定义基类，不能被实例化，可以有构造函数和抽象方法
abstract class Animal {
  String name;
  Animal(this.name);
  void speak();
  void breathe() {
    print('$name is breathing');
  }
}

// extends：继承父类的所有属性和方法，可以调 super
class Dog extends Animal {
  Dog(String name) : super(name);
  @override
  void speak() => print('Woof');
}

// implements：实现接口，全部必须重写，不能调 super
class Cat implements Animal {
  @override
  String name;
  Cat(this.name);
  @override
  void speak() => print('Meow');
  @override
  void breathe() => print('$name is breathing');
}

// mixin：可复用的代码片段，不能有构造函数，可以有抽象方法
mixin Flyable {
  void fly() => print('Flying!');
}

mixin Swimmable {
  void swim() => print('Swimming!');
}

// with：混入 mixin，可以混入多个，也可与 extends 组合使用
class Duck extends Animal with Flyable {
  Duck(String name) : super(name);
  @override
  void speak() => print('Quack');
}

// mixin 可以有抽象方法，要求混入类实现
mixin HasName {
  String get name;
  void introduce() => print('My name is $name');
}

class Person with HasName {
  @override
  String get name => 'Alice';
}

// implements vs with：
// implements → 全部重写，不能复用（遵循规范）
// with → 直接复用已有实现，可选重写（组合能力）
class Plane with Flyable { }

// with 可以同时混入多个 mixin
class SuperDuck extends Animal with Flyable, Swimmable {
  SuperDuck(String name) : super(name);
  @override
  void speak() => print('Super Quack');
}
```

---

### 5. Dart 中 == 与 identical 的区别是什么？

`==` 判断**值相等**（equals），`identical` 判断**引用相等**（是否是同一个对象）。

| 维度 | `==` | `identical` |
|------|------|------------|
| 判断依据 | 值是否相等 | 是否是同一个内存对象 |
| 可自定义 | ✅ 可以 override | ❌ 不能 override |
| 默认行为 | 等同于 `identical`（未 override 时） | 比较内存地址 |
| 使用场景 | 比较两个对象的值是否相同 | 比较两个变量是否指向同一实例 |

```dart
// String 和 int 等基本类型，== 和 identical 结果相同
var a = 'hello';
var b = 'hello';
print(a == b);               // true（值相等）
print(identical(a, b));      // true（字符串常量池，指向同一对象）

// 自定义对象，== 默认等同于 identical
class Point {
  final int x, y;
  Point(this.x, this.y);
}

var p1 = Point(1, 2);
var p2 = Point(1, 2);
print(p1 == p2);             // false（默认 == 比较的是引用，p1 和 p2 不同对象）
print(identical(p1, p2));    // false（不同内存地址）

// override == 后，== 和 identical 行为不同
class EquatablePoint {
  final int x, y;
  EquatablePoint(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      other is EquatablePoint && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);
}

var e1 = EquatablePoint(1, 2);
var e2 = EquatablePoint(1, 2);
print(e1 == e2);             // true（值相等，override 后比较 x 和 y）
print(identical(e1, e2));    // false（不同内存地址）

// const 的特殊性：相同参数的 const 对象是同一实例
const c1 = EquatablePoint(1, 2);
const c2 = EquatablePoint(1, 2);
print(identical(c1, c2));    // true（编译时常量，同一对象）
```

---

### 6. Dart 是否支持多继承？如果不支持，如何替代？

**不支持**。Dart 是单继承语言，一个类只能有一个父类（extends）。

**替代方案**：

| 方案 | 关键字 | 特点 | 适用场景 |
|------|--------|------|---------|
| **混入（Mixin）** | `with` | 复用多个 mixin 的代码实现，解决菱形继承问题 | 需要组合多种能力的场景 |
| **接口（Implements）** | `implements` | 实现多个接口，强制遵循规范（Dart 中每个类都是隐式接口，普通类也可被 implements） | 需要满足多个约定，不关心代码复用 |
| **组合** | 手动委托 | 类内部持有其他类的实例，委托调用 | 需要灵活控制委托逻辑 |

```dart
// ❌ Dart 不支持多继承
// class Bat extends Animal, Flyable { }  // 编译错误

// ✅ 方案 1：Mixin 混入
mixin Flyable {
  void fly() => print('Flying');
}
mixin Nocturnal {
  void hunt() => print('Hunting at night');
}

class Bat extends Animal with Flyable, Nocturnal {
  Bat(String name) : super(name);
  @override
  void speak() => print('Screech');
}

// ✅ 方案 2：Implements 多个接口
abstract class Swimmer {
  void swim();
}
abstract class Diver {
  void dive();
}

class Human implements Swimmer, Diver {
  @override
  void swim() => print('Swimming');
  @override
  void dive() => print('Diving');
}

// ✅ 方案 3：组合（Composition over Inheritance）
class Engine {
  void start() => print('Engine started');
}

class Wheel {
  void rotate() => print('Wheel rotating');
}

class Car {
  final Engine _engine = Engine();
  final Wheel _wheel = Wheel();

  void start() => _engine.start();  // 委托给 Engine
  void move() {
    _engine.start();
    _wheel.rotate();
  }
}
```

---

### 7. Dart 中 covariant 的含义是什么？

`covariant` 用于在子类覆写方法时，允许将参数类型收窄为更具体的子类型。

```dart
class Animal {
  void feed(covariant Animal food) {
    print('Feeding animal');
  }
}

class Cat extends Animal {
  @override
  void feed(covariant Cat food) {  // 参数类型从 Animal 收窄为 Cat
    print('Feeding cat');
  }
}

class Dog extends Animal {
  @override
  void feed(covariant Dog food) {  // 参数类型从 Animal 收窄为 Dog
    print('Feeding dog');
  }
}
```

**为什么需要 covariant？**

正常情况下，Dart 不允许覆写方法时改变参数类型（参数是 contravariant，返回值是 covariant）。但某些场景下需要参数类型收窄，此时用 `covariant` 告诉编译器"我知道这样做是安全的"。

**不使用 covariant 的替代写法**：

```dart
class Animal {
  void feed(Animal food) {
    print('Feeding animal');
  }
}

class Cat extends Animal {
  @override
  void feed(Animal food) {
    if (food is Cat) {           // 运行时检查类型
      print('Feeding cat');
    }
  }
}
```

**covariant 的本质**：关闭编译器的类型安全检查，允许参数类型收窄，类型错误会推迟到运行时暴露。

---

### 8. Future.microtask 与普通 Future 的区别是什么？

两者都用于创建异步任务，区别在于它们在**事件循环（Event Loop）中的执行优先级**。

| 维度 | `Future()`（普通 Future） | `Future.microtask()` |
|------|-------------------------|---------------------|
| **任务队列** | 事件队列（Event Queue） | 微任务队列（Microtask Queue） |
| **执行时机** | 当前微任务执行完后，从事件队列取 | 当前同步代码执行完后，立刻执行 |
| **优先级** | 低 | 高 |
| **嵌套执行** | 每次 await 都会回到事件队列尾部 | 连续 microtask 会在同一帧内执行完 |
| **典型场景** | 网络请求、文件读写、定时器 | 需要尽快执行的小任务（如回调通知、状态标记） |

**Dart 事件循环的执行顺序**：

```
开始当前帧
  │
  ├── 执行所有同步代码
  │
  ├── 执行所有微任务（Microtask Queue），直到清空
  │   ├── Future.microtask()
  │   ├── scheduleMicrotask()
  │   └── 异步回调的后续微任务
  │
  ├── 执行一个事件任务（Event Queue）
  │   ├── Future()（普通）
  │   ├── 网络 I/O 回调
  │   ├── 定时器回调
  │   └── UI 事件
  │
  └── 渲染帧（Flutter）/ 休眠
```

```dart
import 'dart:async';

void main() {
  print('1: 同步代码开始');

  Future(() => print('3: 普通 Future（事件队列）'));

  Future.microtask(() => print('2: microtask（微任务队列）'));

  Future(() => print('5: 另一个普通 Future'));

  Future.microtask(() => print('4: 另一个 microtask'));

  print('1: 同步代码结束');
}

// 输出顺序：
// 1: 同步代码开始
// 1: 同步代码结束
// 2: microtask（微任务队列）   ← 微任务优先
// 4: 另一个 microtask          ← 同一帧内所有微任务执行完
// 3: 普通 Future（事件队列）    ← 再取事件队列
// 5: 另一个普通 Future
```

**嵌套场景的差异**：

```dart
// 普通 Future 嵌套：每次 await 回到事件队列尾部
Future(() {
  print('Future 1');
}).then((_) {
  print('Future 1.then');       // 微任务，紧跟在 Future 1 之后
});

Future(() {
  print('Future 2');            // 在 Future 1.then 之后执行
});

// 输出：Future 1 → Future 1.then → Future 2

// microtask 嵌套：所有 microtask 连续执行
Future.microtask(() {
  print('Microtask 1');
}).then((_) {
  print('Microtask 1.then');    // 微任务，紧跟在 Microtask 1 之后
});

Future.microtask(() {
  print('Microtask 2');         // 也在 Microtask 1.then 之后执行
});

// 输出：Microtask 1 → Microtask 1.then → Microtask 2
```

**使用建议**：

| 场景 | 推荐 | 原因 |
|------|------|------|
| 网络请求、文件 I/O | `Future()` | 不需要立即执行，等事件队列轮到即可 |
| 回调通知、状态同步 | `Future.microtask()` | 尽快执行，避免大量异步累积 |
| 避免栈溢出 | `Future.microtask()` | 用递归 microtask 替代同步递归分散到多帧 |
| Flutter setState | `Future.microtask()` | 在当前帧构建完成后尽快触发重绘 |

---

### 9. Dart 中的事件循环机制是怎样的？

Dart 是**单线程模型**，通过**事件循环（Event Loop）** 实现异步。事件循环维护两个队列：

| 队列 | 优先级 | 包含的任务 | 特点 |
|------|--------|-----------|------|
| **Microtask Queue（微任务队列）** | 🔴 高 | `Future.microtask()`、`scheduleMicrotask()`、`.then()` 回调 | 当前帧内全部执行完 |
| **Event Queue（事件队列）** | 🟢 低 | `Future()`、网络 I/O、定时器、UI 事件 | 每次只取一个执行 |

**事件循环的执行流程**：

```
① 执行所有同步代码
        │
        ▼
② 检查 Microtask Queue ── 有任务 ──▶ 取出一个执行
        │                                    │
        │                                    ▼
        │                             执行完毕后回到 ②
        │
        ▼
③ Microtask Queue 为空
        │
        ▼
④ 从 Event Queue 取出一个任务执行
        │
        ▼
⑤ 执行完毕后回到 ②
```

**关键规则**：**每次从 Event Queue 取一个事件前，必须清空整个 Microtask Queue。**

```dart
import 'dart:async';

void main() {
  // 同步代码
  print('A: 同步代码');

  // 微任务
  Future.microtask(() => print('B: microtask 1'));
  Future.microtask(() => print('C: microtask 2'));

  // 事件队列
  Future(() => print('D: Future 1'));

  // 同步代码
  print('E: 同步代码结束');
}

// 输出：
// A: 同步代码
// E: 同步代码结束      ← 同步代码全部执行完
// B: microtask 1       ← 清空微任务队列
// C: microtask 2       ← 微任务队列清空
// D: Future 1          ← 从事件队列取一个
```

**Three 层模型**：

```
                           Dart 程序入口
                                │
                                ▼
                    ┌──────────────────────┐
                    │    同步代码执行         │
                    │  main() 中的全部代码   │
                    └──────────┬───────────┘
                               │
                               ▼
              ┌────────────────────────────────┐
              │     清空 Microtask Queue        │ ← 高优先级
              │  Future.microtask()            │
              │  scheduleMicrotask()           │
              │  .then() / .catchError()       │
              └──────────────┬─────────────────┘
                             │
                             ▼
              ┌────────────────────────────────┐
              │  取一个 Event Queue 任务执行    │ ← 低优先级
              │  Future()                      │
              │  Timer                         │
              │  I/O 回调                      │
              │  UI 事件（Flutter）            │
              └──────────────┬─────────────────┘
                             │
                             ▼
                    回到「清空 Microtask Queue」
```

**.then() 为什么是微任务？**

```dart
Future(() => print('Event 1'))
  .then((_) => print('Microtask from Event 1'));

Future(() => print('Event 2'));

// 输出：
// Event 1              ← 事件队列中的第一个 Future
// Microtask from Event 1  ← .then() 是微任务，在 Event 2 之前执行
// Event 2              ← 清空微任务后，再从事件队列取
```

**实际应用**：Flutter 的渲染流程就依赖事件循环：

```
用户触摸
  │
  ▼
同步事件分发
  │
  ▼
清空微任务（处理动画回调等）
  │
  ▼
构建（build） → 布局（layout） → 绘制（paint）
  │
  ▼
渲染帧（Vsync 信号触发下一轮事件循环）
```

---

### 10. Dart 的类能用 final 修饰吗？

**可以。** Dart 3.0+ 引入 `final class`，表示**该类不可被继承、不可被实现、不可被混入**。

| 修饰符 | 能否 extends | 能否 implements | 能否 mixin | 能否实例化 |
|--------|------------|---------------|-----------|-----------|
| `class`（默认） | ✅ | ✅ | ✅ | ✅ |
| `final class` | ❌ | ❌ | ❌ | ✅ |
| `base class` | ✅（仅同库） | ❌ | ❌ | ✅ |
| `sealed class` | ✅（同文件） | ❌ | ❌ | ❌ |
| `abstract class` | ✅ | ✅ | ❌（无构造函数） | ❌ |

```dart
final class Config {
  final String apiKey;
  Config(this.apiKey);
}

// ❌ 编译错误：final class 不能被继承
// class DevConfig extends Config { }

// ❌ 编译错误：final class 不能被实现
// class MockConfig implements Config { }

// ✅ 可以正常实例化
var config = Config('secret_key');
print(config.apiKey);
```

**为什么需要 final class？**
- 防止滥用继承破坏封装（类似 Java 的 final class）
- 框架设计者可以用 final 约束 API 不被篡改
- 美团团的类安全——不需要考虑子类覆写带来的兼容性问题
