# iOS NSMutableArray 底层分析

## 一、类簇架构

### 1.1 什么是类簇（Class Cluster）

类簇是**抽象工厂模式**在 Objective-C 中的实现。其核心思想：

- 对外暴露一个**抽象基类**（如 `NSArray`/`NSMutableArray`），提供统一的公开接口
- 内部根据使用场景，返回不同的**具体私有子类**，各自有独立的实现策略
- 调用者无需关心实际类型，只通过基类接口操作

```
           NSArray（抽象基类）
          ┌────┴────┐
     __NSArrayI    __NSArray0
     （普通数组）    （空数组优化）

        NSMutableArray（抽象基类）
          ┌────┴────┐
     __NSArrayM    __NSFrozenArrayM
     （可变数组）    （冻结数组优化）
```

### 1.2 NSArray/NSMutableArray 的类簇成员

| 实际类 | 用途 | 特点 |
|--------|------|------|
| `__NSArrayI` | 不可变数组（有元素） | 核心实现类，直接存储 C 数组 |
| `__NSArray0` | 不可变空数组 | 零元素优化，共享单例 |
| `__NSSingleObjectArrayI` | 单元素不可变数组 | 仅存 1 个对象时优化 |
| `__NSArrayM` | 可变数组 | 环形缓冲区，本文重点分析 |
| `__NSFrozenArrayM` | 冻结可变数组 | 从可变数组 copy 出来时使用 |

**验证方法**：

```objc
// 不同创建方式返回不同子类
NSArray *empty = @[];                    // __NSArray0
NSArray *single = @[@"hi"];              // __NSSingleObjectArrayI
NSArray *normal = @[@"a", @"b"];         // __NSArrayI
NSMutableArray *mutable = [NSMutableArray array]; // __NSArrayM

// 打印实际类名
NSLog(@"%s", object_getClassName(empty));    // __NSArray0
NSLog(@"%s", object_getClassName(single));   // __NSSingleObjectArrayI
NSLog(@"%s", object_getClassName(normal));   // __NSArrayI
NSLog(@"%s", object_getClassName(mutable));  // __NSArrayM
```

### 1.3 为什么使用类簇？

| 优势 | 说明 |
|------|------|
| **接口简化** | 调用者只需知道 `NSArray`/`NSMutableArray`，不需要理解 5+ 种内部子类 |
| **场景优化** | 空数组不需要分配 buffer（`__NSArray0`），单元素数组不需要容量管理（`__NSSingleObjectArrayI`） |
| **实现隔离** | 私有子类可以自由变更实现（如 `__NSArrayM` 换环形缓冲区、`__NSArrayI` 用线性数组），不影响外部 |
| **二进制兼容** | 新增私有子类（如 `__NSFrozenArrayM`）不破坏已有代码，因为外部只依赖基类接口 |

### 1.4 类簇的设计模式

类簇对应 GoF 的**抽象工厂模式**：

```
┌─────────────────────────────────────────────────────────────────┐
│                        调用者                                    │
│  NSArray *array = [NSArray arrayWithObject:@"hello"];            │
│  // 只知道是 NSArray，不知道具体子类                                │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                  抽象基类（工厂）                                  │
│  NSArray / NSMutableArray                                       │
│  - 定义公开接口（count, objectAtIndex: 等）                       │
│  - 工厂方法（array, arrayWithObject: 等）决定返回哪个子类           │
│  - 需子类实现的方法抛出 subclassResponsibility                    │
└────────────────────────────┬────────────────────────────────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
        __NSArrayI    __NSArray0    __NSSingleObjectArrayI
        （具体产品A）  （具体产品B）  （具体产品C）
        各自独立实现   各自独立实现   各自独立实现
```

### 1.5 类簇的继承限制

因为类簇使用 `subclassResponsibility`，直接继承 `NSMutableArray` 需要实现所有 7 个原始方法，否则调用会抛异常：

```objc
// ❌ 直接继承 NSMutableArray — 必须实现 7 个原始方法
@interface MyArray : NSMutableArray
@end
// 调用 addObject: → NSInternalInconsistencyException
// "Method defined in subclass must implement..."

// ✅ 正确方式 — 继承具体子类或组合模式
@interface MyArray : NSObject {
    NSMutableArray *_internal;
}
- (NSUInteger)count { return [_internal count]; }
- (id)objectAtIndex:(NSUInteger)index { return [_internal objectAtIndex:index]; }
@end
```

Apple 官方推荐**组合而非继承**来扩展类簇类。

### 1.6 其他 iOS 类簇举例

类簇在 iOS Foundation 中广泛使用：

| 抽象基类 | 私有子类 | 场景 |
|---------|---------|------|
| `NSString` | `__NSCFString`, `NSCFConstantString`, `NSTaggedPointerString` | 小字符串优化（Tagged Pointer） |
| `NSNumber` | `__NSCFNumber`, `NSCFConstantNumber`, `NSTaggedPointerNumber` | 不同数值类型（int/float/double 等） |
| `NSDictionary` | `__NSDictionaryI`, `__NSDictionaryM`, `__NSFrozenDictionaryM` | 不可变/可变/冻结 |
| `NSSet` | `__NSSetI`, `__NSSetM` | 不可变/可变 |
| `NSDate` | `__NSDate`, `NSCalendarDate`（旧版） | 时间表示 |
| `UIButton` | 多个私有子类 | 不同 buttonType（system/custom 等） |

**Tagged Pointer 特殊案例**：`NSTaggedPointerString` 和 `NSTaggedPointerNumber` 不走类簇的分配路径，而是将值直接编码在指针本身中（不分配任何对象内存），是类簇设计的极致优化。

---

### 1.7 NSMutableArray 的类簇机制验证

```objc
NSMutableArray *array = [NSMutableArray array];
// object_getClass(array) → __NSArrayM
```

`NSMutableArray` 的 `insertObject:atIndex:`、`removeObjectAtIndex:`、`addObject:` 等方法都调用了 `subclassResponsibility`，表示必须由子类实现。`__NSArrayM` 就是这个核心子类。

---

## 二、__NSArrayM 内部结构

通过 `class-dump` 导出 CoreFoundation 二进制，得到 `__NSArrayM` 的完整 ivar 布局：

### 2.1 ARM64 版本（iOS 7.0+ SDK）

```objc
@interface __NSArrayM : NSMutableArray
{
    unsigned long long _used;              // 当前存储的元素数量
    unsigned long long _doHardRetain:1;    // 1-bit 标志：硬引用
    unsigned long long _doWeakAccess:1;    // 1-bit 标志：弱访问
    unsigned long long _size:62;           // 62-bit 位域：缓冲区总容量
    unsigned long long _hasObjects:1;      // 1-bit 标志：是否有对象
    unsigned long long _hasStrongReferences:1; // 1-bit 标志：强引用语义
    unsigned long long _offset:62;         // 62-bit 位域：首元素在缓冲区中的索引
    unsigned long long _mutations;         // 变异计数器（用于枚举期间检测修改）
    id *_list;                             // 缓冲区指针
}
```

### 2.2 字段含义

| 字段 | 含义 |
|------|------|
| `_used` | 数组当前实际存储的元素个数 |
| `_list` | 环形缓冲区（id 指针数组）的首地址 |
| `_size` | 环形缓冲区的总容量（62-bit 位域，实际值需右移 2 位提取） |
| `_offset` | 数组逻辑首元素在环形缓冲区中的起始索引（62-bit 位域，右移 2 位提取） |
| `_mutations` | 变异计数器，每次修改操作递增，用于枚举时检测并发修改 |
| `_doHardRetain` / `_doWeakAccess` | 与 `_size` 共享同一 64-bit 存储单元的标志位 |
| `_hasObjects` / `_hasStrongReferences` | 与 `_offset` 共享同一 64-bit 存储单元的标志位 |

### 2.3 位域提取

`_size` 和 `_offset` 使用 62-bit 位域存储在 64-bit 字中（剩余 2 bit 存标志位），提取实际值需要右移 2 位：

```asm
lsr  x8, x8, #0x2    ; _size >> 2 → 实际容量
lsr  x9, x9, #0x2    ; _offset >> 2 → 实际偏移
```

---

## 三、环形缓冲区（Circular Buffer）核心原理

`__NSArrayM` 底层使用**环形缓冲区**作为数据结构。环形缓冲区的核心特性：当内容到达边界时，可以回绕到另一端。

### 3.1 内存布局示意

```
__NSArrayM 结构：
┌──────────────────────────────────────────────────────────────────┐
│  _list (id 指针数组)                                              │
│  [__][__][obj0][obj1][obj2][obj3][obj4][__]                       │
│   0   1    2     3     4     5     6    7                        │
│                    ↑ _offset = 3                                   │
│                    ← 首元素从这里开始                                │
│  _used = 5  _size = 8                                             │
└──────────────────────────────────────────────────────────────────┘
```

### 3.2 索引访问计算

访问逻辑索引 `i` 时，实际缓冲区位置计算公式：

```
fetchOffset = _offset + i
if (_size > fetchOffset) {
    realOffset = fetchOffset          // 未跨越边界
} else {
    realOffset = fetchOffset - _size  // 跨越边界，回绕
}
```

本质上就是对 `_size` 取模：`realOffset = (_offset + i) % _size`

#### 示例 1：简单情况（_size > fetchOffset）

```
Buffer:  [__][__][obj0][obj1][obj2][obj3][obj4][__]
Index:    0   1    2     3     4     5     6    7
                       ↑ _offset=3

访问 index=0: fetchOffset=3, _size(8)>3 → realOffset=3 → _list[3]
访问 index=4: fetchOffset=7, _size(8)>7 → realOffset=7 → _list[7]
```

#### 示例 2：回绕情况（_size ≤ fetchOffset）

```
Buffer:  [obj4][obj5][__][__][__][obj0][obj1][obj2][obj3][__]
Index:    0     1    2   3   4    5     6     7     8    9
                                     ↑ _offset=7

访问 index=0: fetchOffset=7, _size(10)>7 → realOffset=7 → _list[7]
访问 index=4: fetchOffset=11, _size(10)≤11 → realOffset=1 → _list[1]
```

---

## 四、各操作的时间复杂度与实现

### 4.1 objectAtIndex: — O(1)

ARM64 汇编还原为 C 代码：

```objc
- (id)objectAtIndex:(NSUInteger)index
{
    if (_used <= index) {
        // 抛出 NSRangeException
    }
    NSUInteger fetchOffset = _offset + index;
    NSUInteger realOffset = fetchOffset - (_size > fetchOffset ? 0 : _size);
    return _list[realOffset];
}
```

**关键汇编细节**：
- **脆弱基类处理**：ivar 偏移量不是硬编码常量，而是从固定内存地址加载（如 `_OBJ_IVAR_$___NSArrayM._used`），运行时动态更新，保持二进制兼容性
- **指针大小**：`lsl #3`（左移 3 =乘 8）对应 64-bit 指针大小（每个元素 8 字节）
- **条件选择**：`csel` 指令实现三元运算：`_size > fetchOffset ? 0 : _size`

### 4.2 首部插入 insertObject:atIndex:0 — O(1)

新元素放在缓冲区空闲位置，只需更新 `_offset`，**不需要 memmove**：

```
Before: [__][@(0)][@(1)][@(2)][@(3)][__]   _offset=1
After:  [@(0)][@(1)][@(2)][@(3)][__][@(15)] _offset=5

新元素放在缓冲区末尾，_offset 移到 5
没有 memmove！
```

### 4.3 尾部插入 addObject: — O(1)（缓冲区未满时）

直接将元素放在环形缓冲区下一个可用槽位，只需更新 `_used`。

### 4.4 首部删除 removeObjectAtIndex:0 — O(1)

```
Before: [@(0)][@(1)][@(2)][@(3)][@(4)][__]  _offset=0
After:  [__][@(1)][@(2)][@(3)][@(4)][__]    _offset=1

仅 _offset 递增，没有 memmove！
```

### 4.5 尾部删除 removeLastObject — O(1)

仅递减 `_used` 并置空对应槽位，不需要移动元素。

### 4.6 中间插入/删除 — O(n)（最小化移动）

**核心策略**：选择需要移动元素**较少的一侧**进行移动。

#### 中间删除示例（靠近尾部）

```
删除 index=3（更靠近尾部）：
尾部元素向上移动：
[0] @(0)
[1] @(1)
[2] @(2)
[3] @(4)     ← 从位置 4 上移
[4] @(5)     ← 从位置 5 上移
[5] 悬空指针（未清除！）
```

#### 中间删除示例（靠近头部）

```
删除 index=2（更靠近头部）：
头部元素向下移动：
[0] @(0)     ← 位置不变
[1] 悬空指针
[2] @(1)     ← 从位置 1 下移
[3] @(3)
[4] @(4)
[5] @(5)
```

---

## 五、扩容策略

### 5.1 扩容因子 = 1.625×

当环形缓冲区满时需要扩容，`__NSArrayM` 的扩容因子为 **1.625×**（而非 2×）。

| 扩容因子 | 优点 | 缺点 |
|---------|------|------|
| 2× | 简单、保证 O(1) 平均插入 | 内存浪费严重，已分配内存无法复用 |
| 1.625× | 内存更高效、平衡分配频率和浪费 | 稍多分配次数 |

**为什么不选 2×？** 2 的幂次分配会导致严重的内存浪费——先前释放的内存块因为尺寸不同，几乎无法被后续分配复用。1.625 因子在内存效率和分配频率之间取得平衡。（Facebook Folly 的 FBVector 文档有详细分析）

### 5.2 实际验证

```
初始容量设置 → 实际缓冲区大小：
1  → 2
2  → 2
4  → 4
8  → 8
16 → 16
32 → 16  ← 超过 16 的请求被截断为 16
64 → 16
128 → 16
... → 16（始终上限为 16）
```

**结论**：小容量请求大致匹配，超过 16 的初始容量请求被截断为 16。`initWithCapacity:` 参数的影响几乎可以忽略。

### 5.3 永不缩容

一旦缓冲区扩容，`__NSArrayM` **永不缩容**，即使删除所有元素：

```objc
NSMutableArray *array = [NSMutableArray array];
for (int i = 0; i < 10000; i++) {
    [array addObject:[NSObject new]];
}
[array removeAllObjects];
// 输出：Size: 14336 ← 缓冲区仍然很大！
```

**实际影响**：日常使用中不会造成问题。只有在加载大量数据后清空数组、期望回收内存的场景下才需要注意。

---

## 六、指针清理行为

### 6.1 删除时不清除悬空指针

中间插入/删除移动元素时，**不会清除被覆盖位置的原指针**：

```
删除 index=1 三次后：
[0] @(0)
[1] 悬空指针（旧 @(1) 的值残留）
[2] 悬空指针
[3] 悬空指针
[4] @(4)
[5] @(5)
```

### 6.2 ARC 安全处理

这些悬空指针如果不处理，ARC 尝试 retain/release 会导致崩溃。`__NSArrayM` 将 `_list` 声明为 `void **`（而非 `id *`），正是为了**避免 ARC 对悬空指针的干预**。

### 6.3 首部删除会清除指针

```objc
// removeObjectAtIndex:0 的实现
[0] 0x0   // 已清除
[1] 0x0   // 已清除
[2] @(2)
[3] @(3)
```

首部删除时，被移除的槽位会被置为 nil，因为 `_offset` 向前移动后这些位置不再属于活跃范围。

---

## 七、子类必须实现的 7 个原始方法

根据 `NSMutableArray` Class Reference，子类必须实现以下 7 个原始方法：

| # | 方法 | 说明 |
|---|------|------|
| 1 | `- count` | 返回元素数量 |
| 2 | `- objectAtIndex:` | 按索引访问元素 |
| 3 | `- insertObject:atIndex:` | 在指定位置插入元素 |
| 4 | `- removeObjectAtIndex:` | 删除指定位置元素 |
| 5 | `- addObject:` | 尾部添加元素 |
| 6 | `- removeLastObject` | 删除尾部元素 |
| 7 | `- replaceObjectAtIndex:withObject:` | 替换指定位置元素 |

`__NSArrayM` 只实现了这 7 个原始方法。`NSMutableArray` 类级别的其他 21+ 方法都基于这 7 个方法实现。

**示例**：`removeAllObjects` 的实现只是反向遍历调用 `removeObjectAtIndex:`：

```objc
NSInteger count = (NSInteger)[self count];
if (count == 0) return;
count--;
do {
    [self removeObjectAtIndex:count];
    count--;
} while (count >= 0);
```

**例外**：`__NSArrayM` 覆写了 `- countByEnumeratingWithState:objects:count:`（NSFastEnumeration），提供更高效的枚举实现。

---

## 八、与 CFArray 的对比

`NSArray/NSMutableArray` 和 `CFArray` **没有任何共享实现**，是完全独立的代码路径。

| 特性 | __NSArrayM | CFArray |
|------|-----------|---------|
| 数据结构 | 环形缓冲区 | 两端零填充的线性缓冲区 |
| 首部插入 | 回绕到缓冲区末尾 | 扩展到头部填充区 |
| 枚举 | 需偏移取模 | 更简单（直接索引） |
| 源码 | 闭源 | 开源（Apple 开源仓库） |
| 扩容策略 | 1.625× | 不同 |

两者都是**双端队列（deque）** 的实现，但策略不同。

---

## 九、完整验证实验

以下通过自定义结构体模拟 `__NSArrayM` 内存布局，验证环形缓冲区的各种操作表现：

### 9.1 测试结构体定义

```objc
typedef struct {
    void **list;        // 缓冲区首地址
    unsigned int offset; // 首元素位置索引
    unsigned int size;   // 总大小
    union {
        unsigned long long mutations;
        struct {
            unsigned int muts;
            unsigned int used;  // 实际使用量
        };
    } state;
} CDStruct_a6934631;

@interface ZHMutableArray : NSObject {
    @public void *cow;
    @public CDStruct_a6934631 storage;
}
@end
```

### 9.2 验证结果

```
1. 初始化（容量=1）
   offset:0, size:2, used:0
   [0](null) | [1](null)

2. addObject:A, addObject:B
   offset:0, size:2, used:2
   [0]A | [1]B

3. insertObject:C atIndex:0（首部插入）
   offset:3, size:4, used:3
   [0]A | [1]B | [2](null) | [3]C
   ← C 放在缓冲区末尾（index=3），_offset 从 0 变为 3

4. removeObjectAtIndex:0（首部删除）
   offset:0, size:4, used:2
   [0]A | [1]B | [2](null) | [3]C
   ← _offset 回到 0，跳过了 index=3 的 C

5. insertObject:D atIndex:1（中间插入）
   offset:0, size:4, used:3
   [0]A | [1]D | [2]B | [3]C
   ← B 被右移，D 占据 index=1

6. insertObject:E atIndex:1（中间插入）
   offset:3, size:4, used:4
   [0]E | [1]D | [2]B | [3]A
   ← 缓冲区已满，选择移动头部（只移动 1 个元素）

7. removeObjectAtIndex:2（中间删除）
   offset:3, size:4, used:3
   [0]E | [1]B | [2]B(悬空) | [3]A
   ← 选择移动头部（1 个元素 vs 2 个元素）

8. removeLastObject（尾部删除）
   offset:3, size:4, used:2
   [0]E | [1]B | [2]B(悬空) | [3]A

9. removeAllObjects
   offset:0, size:0, used:0
   ← 缓冲区完全清空，size 也变为 0
```

### 9.3 关键发现

| # | 发现 | 说明 |
|---|------|------|
| 1 | 扩容为偶数 | 初始化或添加元素时，`_size` 自动扩容为偶数（2 的倍数） |
| 2 | 首部操作仅更新 _offset | 首位置插入/删除不移动旧元素，只更新 `_offset` |
| 3 | 删除不清除指针 | 删除元素后缓冲区内的元素指针不会被清除，仅被移动覆盖 |
| 4 | 删除不缩容 | 删除元素后 `_size` 不减小，只有 `removeAllObjects` 会将 size 清 0 |
| 5 | 中间操作最小化移动 | 中间插入/删除选择移动元素较少的一侧 |
| 6 | 尾部悬空指针 | 移动后最后一个位置的旧指针不会被清除（没有被覆盖） |

---

## 十、时间复杂度总结

| 操作 | 时间复杂度 | 是否需要 memmove |
|------|-----------|----------------|
| `objectAtIndex:` | O(1) | 否 |
| `addObject:`（尾部添加） | O(1) | 否（缓冲区未满时） |
| `insertObject:atIndex:0`（首部插入） | O(1) | 否 |
| `removeObjectAtIndex:0`（首部删除） | O(1) | 否 |
| `removeLastObject`（尾部删除） | O(1) | 否 |
| `insertObject:atIndex:n`（中间插入） | O(n) | 是（最小化移动） |
| `removeObjectAtIndex:n`（中间删除） | O(n) | 是（最小化移动） |

**结论**：`NSMutableArray` 实质上是一个**双端队列（deque）**，环形缓冲区设计使首尾操作极其高效，可作为栈或队列高效使用，但频繁中间插入/删除仍为 O(n)。

---

## 十一、关键面试题

### 1. NSMutableArray 底层数据结构是什么？

**环形缓冲区**（Circular Buffer / Ring Buffer）。`__NSArrayM` 使用 `_list` + `_offset` + `_size` + `_used` 四个字段实现，逻辑首元素通过 `_offset` 定位，访问时对 `_size` 取模得到实际缓冲区索引。

### 2. 为什么首尾插入删除是 O(1)?

首部插入：将新元素放在缓冲区空闲端，更新 `_offset` 即可，无需移动任何元素。首部删除：仅递增 `_offset`，跳过被删除元素。尾部操作同理，只更新 `_used`。

### 3. 中间插入/删除的策略是什么？

选择需要移动元素**较少的一侧**进行 `memmove`。例如在位置 1 插入，前方只有 1 个元素需移动，后方有 3 个，则移动前方元素并更新 `_offset`。

### 4. NSMutableArray 的扩容因子是多少？

**1.625×**，不是常见的 2×。1.625 在内存效率和分配频率之间取得平衡，避免 2 的幂次导致的内存浪费（已释放的大块内存无法被后续分配复用）。

### 5. 删除元素后缓冲区会缩容吗？

**不会**。除非调用 `removeAllObjects`（会将 `_size` 清 0），其他删除操作只递减 `_used`，缓冲区大小不变。这意味着如果曾加载大量数据后只删除部分元素，内存不会回收。

### 6. NSMutableArray 和 CFArray 是同一实现吗？

**不是**。两者完全独立。`__NSArrayM` 使用环形缓冲区，CFArray 使用两端零填充的线性缓冲区。虽然都是 deque 的实现，但策略和代码完全不同。

---

## 参考链接

- [NSMutableArray 原理揭露](http://blog.joyingx.me/2015/05/03/NSMutableArray%20原理揭露/) — ARM64 汇编逆向分析
- [iOS NSMutableArray 底层分析](https://juejin.cn/post/6905416475675213831) — 环形缓冲区验证实验
- [wiki - 环形缓冲区](https://zh.wikipedia.org/wiki/环形缓冲区)
- [gnustep/libs-base](https://github.com/gnustep/libs-base) — GNUstep Foundation 源码
- [class-dump](http://stevenygard.com/projects/class-dump/) — 导出未加密可执行文件头文件
- [Facebook Folly FBVector](https://github.com/facebook/folly/blob/main/folly/docs/FBVector.md) — 扩容因子分析
