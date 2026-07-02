# Runtime 实际应用

## 一、方法交换（Method Swizzling）

### 1.1 什么是方法交换

方法交换（Method Swizzling）是 Runtime 的一种技术，在运行时交换两个方法的 IMP（方法实现指针），从而在不修改原有代码的情况下，给系统方法或第三方库方法添加额外逻辑。

```
交换前：
  [obj originalMethod]  →  IMP_original
  [obj swizzledMethod]  →  IMP_swizzled

交换后：
  [obj originalMethod]  →  IMP_swizzled  （实际执行的是 swizzledMethod 的代码）
  [obj swizzledMethod]  →  IMP_original  （实际执行的是 originalMethod 的代码）
```

### 1.2 方法交换的完整步骤

#### 核心 API

```objc
// 获取方法的 IMP
class_getMethodImplementation(Class cls, SEL name)

// 获取方法结构体
class_getInstanceMethod(Class cls, SEL name)   // 实例方法
class_getClassMethod(Class cls, SEL name)       // 类方法

// 交换两个方法的 IMP
method_exchangeImplementations(Method m1, Method m2)

// 添加方法（如果目标类没有实现该方法）
class_addMethod(Class cls, SEL name, IMP imp, const char *types)

// 替换方法的 IMP
class_replaceMethod(Class cls, SEL name, IMP imp, const char *types)
```

#### 标准交换流程

```objc
// 完整的方法交换实现（iOS 开发标准写法）

#import <objc/runtime.h>

@implementation UIViewController (Tracking)

+ (void)load {
    // ① 在 +load 中执行，保证只执行一次
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // ② 获取原始方法和交换方法的 SEL
        SEL originalSelector = @selector(viewWillAppear:);
        SEL swizzledSelector = @selector(tracking_viewWillAppear:);

        // ③ 获取 Method 结构体
        Method originalMethod = class_getInstanceMethod(self, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(self, swizzledSelector);

        // ④ 关键步骤：尝试为原始 SEL 添加交换方法的 IMP
        //    如果 self 没有实现 originalSelector（继承自父类），
        //    先添加，避免交换父类的 IMP
        BOOL didAddMethod = class_addMethod(self,
                                            originalSelector,
                                            method_getImplementation(swizzledMethod),
                                            method_getTypeEncoding(swizzledMethod));

        if (didAddMethod) {
            // ⑤ 添加成功：说明 self 原来没有实现 originalSelector
            //    现在 originalSelector 已经指向了 swizzledMethod 的 IMP
            //    需要把 swizzledSelector 的 IMP 改成 originalMethod 的 IMP
            class_replaceMethod(self,
                                swizzledSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        } else {
            // ⑤ 添加失败：说明 self 已经实现了 originalSelector
            //    直接交换两个方法的 IMP
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

- (void)tracking_viewWillAppear:(BOOL)animated {
    // 此时 self 调用 tracking_viewWillAppear: 实际执行的是原始的 viewWillAppear:
    // 所以这里调用 self 并不会死循环
    [self tracking_viewWillAppear:animated];

    // 添加额外的埋点逻辑
    NSLog(@"Tracking: %@ viewWillAppear", NSStringFromClass([self class]));
}

@end
```

### 1.3 方法交换的时序

```
                          +load 时执行
                               │
                               ▼
           ┌─── 检查 self 是否实现了 originalSelector？───┐
           │                                              │
       ❌ 未实现（继承自父类）                     ✅ 已实现（自己实现的）
           │                                              │
           ▼                                              ▼
   class_addMethod(self, original,          method_exchangeImplementations(
     swizzledIMP, types)                      originalMethod, swizzledMethod)
           │                                              │
           ▼                                              ▼
   originalSelector → swizzledIMP              originalSelector → swizzledIMP
   swizzledSelector → originalIMP（原始父类）    swizzledSelector → originalIMP（自己实现）
```

### 1.4 Demo：全局埋点（无侵入统计页面访问）

```objc
// UIViewController+Tracking.m
#import <objc/runtime.h>

@implementation UIViewController (Tracking)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 交换 viewWillAppear:
        [self swizzleInstanceMethod:@selector(viewWillAppear:)
                        withMethod:@selector(tracking_viewWillAppear:)];

        // 交换 viewDidDisappear:
        [self swizzleInstanceMethod:@selector(viewDidDisappear:)
                        withMethod:@selector(tracking_viewDidDisappear:)];
    });
}

+ (void)swizzleInstanceMethod:(SEL)originalSel withMethod:(SEL)swizzledSel {
    Method originalMethod = class_getInstanceMethod(self, originalSel);
    Method swizzledMethod = class_getInstanceMethod(self, swizzledSel);

    BOOL didAdd = class_addMethod(self,
                                  originalSel,
                                  method_getImplementation(swizzledMethod),
                                  method_getTypeEncoding(swizzledMethod));

    if (didAdd) {
        class_replaceMethod(self,
                            swizzledSel,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

- (void)tracking_viewWillAppear:(BOOL)animated {
    // 调用原始实现（方法交换后，这里实际调用的是 viewWillAppear: 的原始 IMP）
    [self tracking_viewWillAppear:animated];

    // 埋点逻辑
    NSString *pageName = NSStringFromClass([self class]);
    NSLog(@"[Tracking] Enter page: %@", pageName);
    // 实际项目中上报给统计 SDK
    // [MobClick beginLogPageView:pageName];
}

- (void)tracking_viewDidDisappear:(BOOL)animated {
    [self tracking_viewDidDisappear:animated];

    NSString *pageName = NSStringFromClass([self class]);
    NSLog(@"[Tracking] Leave page: %@", pageName);
}

@end

// 使用：所有 UIViewController 子类自动获得埋点，无需修改任何业务代码
```

### 1.5 Demo：数组越界防护

```objc
// NSArray+SafeAccess.m
#import <objc/runtime.h>

@implementation NSArray (SafeAccess)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // NSArray 是类簇，实际子类是 __NSArrayI
        // 注意：不能对 NSArray 本身交换，需要对实际子类交换
        Class arrayClass = NSClassFromString(@"__NSArrayI");

        Method originalMethod = class_getInstanceMethod(arrayClass, @selector(objectAtIndex:));
        Method swizzledMethod = class_getInstanceMethod(arrayClass, @selector(safe_objectAtIndex:));

        method_exchangeImplementations(originalMethod, swizzledMethod);
    });
}

- (id)safe_objectAtIndex:(NSUInteger)index {
    if (index >= self.count) {
        NSLog(@"[Safe] 数组越界: index=%lu, count=%lu", (unsigned long)index, (unsigned long)self.count);
        return nil;  // 返回 nil 而不是崩溃
    }
    // 调用原始实现（交换后，safe_objectAtIndex: 指向了原始的 objectAtIndex:）
    return [self safe_objectAtIndex:index];
}

@end
```

### 1.6 方法交换必须注意的事项

#### ⚠️ 事项 1：必须在 +load 中执行，用 dispatch_once 保证只执行一次

```objc
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // ✅ 正确：+load 是线程安全的，dispatch_once 保证只交换一次
    });
}

// ❌ 不要在 +initialize 中交换
// +initialize 是懒加载的，如果子类没有用到分类的方法，+initialize 不会调用
// 而且 +initialize 可能被子类继承调用多次

// ❌ 不要在 -init 或其他实例方法中交换
// 每次创建实例都会交换一次，导致交换多次，IMP 指针错乱
```

#### ⚠️ 事项 2：先调用 class_addMethod 再决定交换方式

```objc
// 为什么需要 class_addMethod？
//
// 场景：UIViewController 本身没有实现 viewWillAppear:
//       viewWillAppear: 是 UIViewController 父类的方法
//
// 如果直接 method_exchangeImplementations：
//   ❌ 会交换掉 UIViewController 父类的 viewWillAppear: IMP
//       → 所有继承自 UIViewController 的子类都会受影响
//       → 但我们的分类只期望影响自己的子类
//
// class_addMethod 的作用：
//   如果 self 没有实现 originalSelector：
//     先把交换方法的 IMP 添加到 self 上（originalSelector → swizzledIMP）
//     再把原始 IMP 赋给 swizzledSelector
//   → 这样只影响 self 及其子类，不影响父类
```

#### ⚠️ 事项 3：交换方法中调用 self 不会死循环

```objc
- (void)tracking_viewWillAppear:(BOOL)animated {
    [self tracking_viewWillAppear:animated];
}
```

**为什么不会死循环？关键在于理解方法交换后 SEL 和 IMP 的映射关系：**

```
交换前：
  viewWillAppear:         →  IMP_original  （父类实现）
  tracking_viewWillAppear: →  IMP_swizzled  （分类实现）

调用 method_exchangeImplementations 后：

  viewWillAppear:         →  IMP_swizzled  ✅ 指向分类的代码
  tracking_viewWillAppear: →  IMP_original  ✅ 指向父类的代码

所以：
  [self viewWillAppear:]           → 执行 tracking_viewWillAppear 里的代码（埋点逻辑）
  [self tracking_viewWillAppear:]  → 执行原始的 viewWillAppear: 里的代码（父类实现）

因此 tracking_viewWillAppear 方法体内调用 [self tracking_viewWillAppear:]
实际调用的不是自己，而是原始的 viewWillAppear: 实现，不会形成死循环。
```

**这个模式称为「Weird Recursion」（奇怪的递归），在面试中经常被问到。**

---

### 方法交换常见问题总结

#### ❌ 问题 1：load 方法重复调用导致交换多次

```objc
// ❌ 错误：没有用 dispatch_once
+ (void)load {
    Method m1 = class_getInstanceMethod(self, @selector(viewWillAppear:));
    Method m2 = class_getInstanceMethod(self, @selector(tracking_viewWillAppear:));
    method_exchangeImplementations(m1, m2);
}
// → load 方法可能被调用多次（子类 + 分类加载时）
// → 交换 2 次：又交换回去了，等于没交换！
// → 交换 3 次：IMP 指向错乱！

// ✅ 正确：dispatch_once 保证只执行一次
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self swizzleMethod];
    });
}
```

#### ❌ 问题 2：子类没有实现该方法，直接交换了父类的 IMP

```objc
// 场景：
//   LGPerson 实现了 personInstanceMethod
//   LGStudent 继承自 LGPerson，没有实现 personInstanceMethod
//   LGStudent 的分类对 personInstanceMethod 做方法交换

// ❌ 直接交换：
Method oriMethod = class_getInstanceMethod([LGStudent class], @selector(personInstanceMethod));
Method swiMethod = class_getInstanceMethod([LGStudent class], @selector(lg_studentInstanceMethod));
method_exchangeImplementations(oriMethod, swiMethod);

// 结果：
//   [s personInstanceMethod] → ✅ LGStudent 有 lg_studentInstanceMethod，正常
//   [p personInstanceMethod] → ❌ 崩溃！
//   原因：LGStudent 没有 personInstanceMethod，直接交换了 LGPerson 的 IMP
//         LGPerson 没有 lg_studentInstanceMethod，IMP 找不到！

// ✅ 正确：先用 class_addMethod 判断是否自己实现
BOOL didAdd = class_addMethod(cls, oriSEL, swiIMP, type);
if (didAdd) {
    // 自己没实现 → 添加成功 → 替换 swizzledSEL 指向原始 IMP
    class_replaceMethod(cls, swizzledSEL, oriIMP, type);
} else {
    // 自己实现了 → 直接交换
    method_exchangeImplementations(oriMethod, swiMethod);
}
```

#### ❌ 问题 3：父类也没实现该方法，导致递归死循环

```objc
// 场景：
//   LGPerson 只有声明，没有实现 personInstanceMethod
//   LGStudent 继承 LGPerson，也没有实现
//   LGStudent 的分类对 personInstanceMethod 做方法交换

// ❌ 问题分析：
//   oriMethod = class_getInstanceMethod(...) → nil（因为谁都没实现）
//   交换后：[self lg_studentInstanceMethod] 内部调用 [self lg_studentInstanceMethod]
//   但 lg_studentInstanceMethod 的 IMP 并没有指向任何原始实现
//   → 自己调自己 → 递归死循环 → 栈溢出崩溃！

// ✅ 正确：先判断 oriMethod 是否为 nil
if (!oriMethod) {
    // 添加一个空实现，避免递归
    class_addMethod(cls, oriSEL, swiIMP, type);
    method_setImplementation(swiMethod, imp_implementationWithBlock(^(id self, SEL _cmd){}));
}

// 完整的安全交换代码：
+ (void)safeSwizzleWithClass:(Class)cls oriSEL:(SEL)oriSEL swizzledSEL:(SEL)swizzledSEL {
    Method oriMethod = class_getInstanceMethod(cls, oriSEL);
    Method swiMethod = class_getInstanceMethod(cls, swizzledSEL);

    // ① 处理 oriMethod 为 nil 的情况（父类也没有实现）
    if (!oriMethod) {
        class_addMethod(cls, oriSEL,
                       method_getImplementation(swiMethod),
                       method_getTypeEncoding(swiMethod));
        method_setImplementation(swiMethod,
                                imp_implementationWithBlock(^(id self, SEL _cmd){}));
    }

    // ② 判断是自己实现还是继承来的
    BOOL didAdd = class_addMethod(cls, oriSEL,
                                 method_getImplementation(swiMethod),
                                 method_getTypeEncoding(swiMethod));
    if (didAdd) {
        class_replaceMethod(cls, swizzledSEL,
                           method_getImplementation(oriMethod),
                           method_getTypeEncoding(oriMethod));
    } else {
        method_exchangeImplementations(oriMethod, swiMethod);
    }
}
```

#### ❌ 问题 4：类方法交换未使用元类

```objc
// ❌ 错误：类方法要用 class_getClassMethod，不能用 class_getInstanceMethod
Method oriMethod = class_getInstanceMethod(cls, @selector(sayHello));  // ❌ 拿不到类方法

// ✅ 正确：类方法存在元类中
Method oriMethod = class_getClassMethod(cls, @selector(sayHello));

// 添加/替换时使用元类
Class metaClass = object_getClass(cls);  // 获取元类
class_addMethod(metaClass, oriSEL, swiIMP, type);
class_replaceMethod(metaClass, swizzledSEL, oriIMP, type);
```

#### ❌ 问题 5：类簇方法交换用了抽象类

```objc
// ❌ 错误：对抽象基类 NSArray 交换无效
Method m1 = class_getInstanceMethod([NSArray class], @selector(objectAtIndex:));
// → NSArray 是抽象类，没有实现 objectAtIndex:，实际子类是 __NSArrayI

// ✅ 正确：找到实际子类
Class realClass = objc_getClass("__NSArrayI");
Method m1 = class_getInstanceMethod(realClass, @selector(objectAtIndex:));

// 常见类簇的实际子类：
//   NSArray        → __NSArrayI
//   NSMutableArray → __NSArrayM
//   NSString       → __NSCFString（或 NSTaggedPointerString）
//   NSDictionary   → __NSDictionaryI
//   NSMutableDictionary → __NSDictionaryM
```

#### ❌ 问题 6：分类中调用了 super 的 load 方法

```objc
// ❌ 错误
+ (void)load {
    [super load];  // 会导致父类的分类再次执行方法交换，造成重复交换
    // ...
}

// ✅ 正确：NSObject 的分类 +load 中不要调用 super
+ (void)load {
    // 直接写交换逻辑，不调用 [super load]
}
```

#### ❌ 问题 7：Swift 中方法的交换限制

```swift
// Swift 方法交换的两个前提：
//   ① 类必须继承自 NSObject
//   ② 方法必须用 @objc dynamic 修饰

class MyClass: NSObject {
    @objc dynamic func myMethod() { }  // ✅ 可以交换
    func normalMethod() { }            // ❌ 纯 Swift 方法，不能交换
}
```

### 方法交换安全写法总结

```objc
// 推荐的完整安全交换写法（直接可用）
+ (void)safeSwizzleInstanceMethod:(SEL)originalSel withMethod:(SEL)swizzledSel {
    [self safeSwizzleWithClass:self oriSEL:originalSel swizzledSEL:swizzledSel];
}

+ (void)safeSwizzleClassMethod:(SEL)originalSel withMethod:(SEL)swizzledSel {
    Class metaClass = object_getClass(self);
    [self safeSwizzleWithClass:metaClass oriSEL:originalSel swizzledSEL:swizzledSel];
}

+ (void)safeSwizzleWithClass:(Class)cls oriSEL:(SEL)oriSEL swizzledSEL:(SEL)swizzledSEL {
    Method oriMethod = class_getInstanceMethod(cls, oriSEL);
    Method swiMethod = class_getInstanceMethod(cls, swizzledSEL);

    // ① 防止父类也没实现 → 递归死循环
    if (!oriMethod) {
        class_addMethod(cls, oriSEL,
                       method_getImplementation(swiMethod),
                       method_getTypeEncoding(swiMethod));
        method_setImplementation(swiMethod,
                                imp_implementationWithBlock(^(id self, SEL _cmd){}));
    }

    // ② 防止子类没实现 → 交换到父类 IMP
    BOOL didAdd = class_addMethod(cls, oriSEL,
                                 method_getImplementation(swiMethod),
                                 method_getTypeEncoding(swiMethod));
    if (didAdd) {
        class_replaceMethod(cls, swizzledSEL,
                           method_getImplementation(oriMethod),
                           method_getTypeEncoding(oriMethod));
    } else {
        method_exchangeImplementations(oriMethod, swiMethod);
    }
}
```

| 问题 | 原因 | 解决方案 |
|------|------|---------|
| 重复交换 | load 调用多次 | dispatch_once |
| 子类没实现，交换到父类 | class_getInstanceMethod 返回父类 Method | class_addMethod 先判断 |
| 父类也没实现，递归死循环 | oriMethod = nil | oriMethod 为空时添加空实现 |
| 类方法交换失败 | 类方法在元类中 | 用 object_getClass 获取元类 |
| 类簇交换无效 | 抽象基类没有实现 | 找实际子类（__NSArrayI 等） |
| super load 导致重复 | [super load] 触发父类分类 load | 不要在 +load 中调 super |
| Swift 交换无效 | 纯 Swift 方法无 Runtime | 用 @objc dynamic 标记 |

#### ⚠️ 事项 4：类簇的特殊处理

```objc
// NSArray、NSMutableArray、NSString 等都是类簇
// 不能直接对抽象基类交换方法，要找到实际子类

// ❌ 错误：对 NSArray 交换，不会影响实际使用的 __NSArrayI
Method m1 = class_getInstanceMethod([NSArray class], @selector(objectAtIndex:));
Method m2 = class_getInstanceMethod([NSArray class], @selector(my_objectAtIndex:));
method_exchangeImplementations(m1, m2);
// → NSArray 是抽象类，没有实现 objectAtIndex:，交换无效！

// ✅ 正确：找到实际子类
Class arrayClass = NSClassFromString(@"__NSArrayI");
Method m1 = class_getInstanceMethod(arrayClass, @selector(objectAtIndex:));
Method m2 = class_getInstanceMethod(arrayClass, @selector(my_objectAtIndex:));
method_exchangeImplementations(m1, m2);

// 常见的类簇实际子类：
//   NSArray        → __NSArrayI（不可变数组）
//   NSMutableArray → __NSArrayM（可变数组）
//   NSString       → __NSCFString
//   NSDictionary   → __NSDictionaryI（不可变字典）
//   NSMutableDictionary → __NSDictionaryM（可变字典）
```

#### ⚠️ 事项 5：注意命名冲突

```objc
// 交换方法名要加前缀，避免和其他分类冲突
// ✅ 正确：加项目前缀
- (void)hook_viewWillAppear:(BOOL)animated;     // 项目前缀 hook_
- (void)xxx_viewWillAppear:(BOOL)animated;      // 或个人前缀 xxx_

// ❌ 错误：使用通用名称，可能和其他分类冲突
- (void)my_viewWillAppear:(BOOL)animated;       // my_ 太通用
- (void)new_viewWillAppear:(BOOL)animated;      // new_ 也可能被用
```

#### ⚠️ 事项 6：多个分类同时交换同一个方法

```objc
// 场景：
//   分类 A 交换了 viewWillAppear:（添加埋点）
//   分类 B 也交换了 viewWillAppear:（添加权限检查）
//
// +load 执行顺序：
//   先编译的分类先执行，后编译的后执行
//
// 结果：
//   后执行交换的分类，其 swizzled 方法调用 [self swizzledMethod]
//   实际上调用的是前一个分类的 swizzled 方法
//   → 形成调用链，所有分类的逻辑都会执行
//   → 但如果中间某个分类的 +load 没有执行，调用链会断开

// 建议：尽量减少方法交换的使用，优先考虑其他方案（如 AOP、Delegate）
```

#### ⚠️ 事项 7：KVO 和方法交换的冲突

```objc
// KVO 通过 isa-swizzling 动态创建子类并重写 setter
// 如果在 KVO 之后进行方法交换，KVO 的动态子类可能被影响

// 建议：
//   方法交换在 +load 中执行（早于任何 KVO 注册）
//   如果在运行时动态交换，需注意 KVO 的影响
```

#### ⚠️ 事项 8：Swift 中方法交换的局限性

```swift
// Swift 中方法交换仅适用于继承自 NSObject 的类
// 纯 Swift 类（不继承 NSObject）没有 Runtime 机制

// Swift 方法交换示例：
extension UIViewController {
    // ❌ 必须用 @objc dynamic 标记，否则交换无效
    @objc dynamic func swizzled_viewWillAppear(_ animated: Bool) {
        swizzled_viewWillAppear(animated)
        print("Swizzled in Swift")
    }

    static func swizzle() {
        // Swift 中使用 Runtime 需要导入 ObjectiveC 桥接
        // 且方法必须用 @objc dynamic 修饰
    }
}

// Swift 中更推荐用 method_exchangeImplementations 替代方案：
//   1. Protocol + Extension（面向协议编程）
//   2. AOP（Aspect Oriented Programming）
//   3. Swift Property Wrappers
```

### 1.7 方法交换的替代方案

| 方案 | 原理 | 优点 | 缺点 |
|------|------|------|------|
| **Method Swizzling** | Runtime IMP 交换 | 无侵入，全局生效 | Runtime 黑魔法，调试困难 |
| **AOP（Aspects）** | 面向切面编程 | 使用简单，可精确控制 | 底层也是 Runtime，性能略低 |
| **Delegate** | 代理回调 | 类型安全，明确 | 需要修改代码，侵入性强 |
| **Notification** | 通知中心 | 解耦，一对多 | 不直接适用于方法拦截 |
| **子类重写** | 继承 + super | 简单直接 | 需要修改对象创建方式 |
| **Proxy（NSProxy）** | 消息转发 | 灵活性高 | 实现复杂 |

### 1.8 面试要点

| 问题 | 要点 |
|------|------|
| 方法交换的原理 | Runtime 修改类的方法列表中的 IMP 指针 |
| 为什么在 +load 执行 | +load 是线程安全的，且只执行一次 |
| 为什么用 dispatch_once | 防止重复交换导致 IMP 链错乱 |
| class_addMethod 的作用 | 防止交换父类的 IMP，只影响当前类 |
| 交换后为什么不会死循环 | 交换后方法名指向对方的 IMP |
| 类簇怎么处理 | 找到实际子类（__NSArrayI 等）再交换 |
| Swift 能用吗 | 只能用于 @objc dynamic 方法 |
| 多个分类交换同一方法 | 形成调用链，依赖 +load 顺序 |

---

## 二、分类添加属性（关联对象）

### 2.1 为什么分类不能直接添加属性

```objc
// 分类中 @property 只会生成 setter/getter 声明，不会生成 _成员变量 和 实现

// ❌ 错误使用
@interface NSObject (MyCategory)
@property (nonatomic, strong) NSString *myProperty;  // 只是声明，没有实例变量
@end

// [obj myProperty] → ❌ crash: unrecognized selector
// [obj setMyProperty:] → ❌ crash: unrecognized selector
```

### 2.2 关联对象的 API

```objc
// 关联对象
void objc_setAssociatedObject(id object, 
                               const void *key, 
                               id value, 
                               objc_AssociationPolicy policy);

// 获取关联对象
id objc_getAssociatedObject(id object, const void *key);

// 移除所有关联对象
void objc_removeAssociatedObjects(id object);
```

### 2.3 关联策略（objc_AssociationPolicy）

| 策略 | 修饰符 | 说明 |
|------|--------|------|
| `OBJC_ASSOCIATION_ASSIGN` | `assign` | 弱引用，不保留 |
| `OBJC_ASSOCIATION_RETAIN_NONATOMIC` | `nonatomic, strong` | 强引用，非原子 |
| `OBJC_ASSOCIATION_COPY_NONATOMIC` | `nonatomic, copy` | 拷贝，非原子 |
| `OBJC_ASSOCIATION_RETAIN` | `atomic, strong` | 强引用，原子 |
| `OBJC_ASSOCIATION_COPY` | `atomic, copy` | 拷贝，原子 |

### 2.4 Demo：分类添加属性

```objc
// UIViewController+Params.m
#import <objc/runtime.h>

@interface UIViewController (Params)

// 分类中声明属性
@property (nonatomic, copy) NSString *pageName;
@property (nonatomic, strong) NSDictionary *params;

@end

// key 的三种常见写法：

// 写法 1：static const void *（推荐）
static const void *kPageNameKey = &kPageNameKey;

// 写法 2：static char（常用）
static char kParamsKey;

// 写法 3：@selector（最简洁）
// 直接用 selector 作为 key

@implementation UIViewController (Params)

- (NSString *)pageName {
    // 写法 1：用 static 指针作 key
    return objc_getAssociatedObject(self, kPageNameKey);
}

- (void)setPageName:(NSString *)pageName {
    objc_setAssociatedObject(self, kPageNameKey, pageName, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSDictionary *)params {
    // 写法 2：用 static char 地址作 key
    return objc_getAssociatedObject(self, &kParamsKey);
}

- (void)setParams:(NSDictionary *)params {
    objc_setAssociatedObject(self, &kParamsKey, params, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

// 用法：
// viewController.pageName = @"Home";
// viewController.params = @{@"id": @"123"};
// 不需要修改 UIViewController 的源码

@end
```

### 2.5 关联对象的注意事项

- 关联对象在被关联对象 dealloc 时会自动释放，**不需要手动 remove**
- key 只需要唯一地址，不关心值，用 `static char` 或 `static void *` 即可
- 尽量使用 `OBJC_ASSOCIATION_COPY_NONATOMIC` 或 `RETAIN_NONATOMIC`（非原子版本性能更好）
- 关联对象不能滥用，会影响对象的 dealloc 速度

---

## 三、其他 Runtime 应用

### 3.1 字典转模型

```objc
@interface NSObject (Model)

+ (instancetype)modelWithDictionary:(NSDictionary *)dict;

@end

@implementation NSObject (Model)

+ (instancetype)modelWithDictionary:(NSDictionary *)dict {
    id obj = [[self alloc] init];

    // 获取当前类的所有属性
    unsigned int count = 0;
    objc_property_t *propertyList = class_copyPropertyList(self, &count);

    for (unsigned int i = 0; i < count; i++) {
        objc_property_t property = propertyList[i];
        const char *name = property_getName(property);
        NSString *key = [NSString stringWithUTF8String:name];

        // 获取字典中的值
        id value = dict[key];
        if (!value) continue;

        // 获取属性类型（用于处理嵌套模型）
        // char *type = property_copyAttributeValue(property, "T");

        // KVC 赋值
        [obj setValue:value forKey:key];
    }

    free(propertyList);
    return obj;
}

@end
```

### 3.2 动态添加方法

```objc
void dynamicMethodIMP(id self, SEL _cmd) {
    NSLog(@"动态添加的方法被调用");
}

+ (BOOL)resolveInstanceMethod:(SEL)sel {
    if (sel == @selector(dynamicMethod)) {
        class_addMethod(self,
                        sel,
                        (IMP)dynamicMethodIMP,
                        "v@:");  // v=void @=id(self) :=SEL(_cmd)
        return YES;
    }
    return [super resolveInstanceMethod:sel];
}
```

### 3.3 消息转发

```objc
// 完整消息转发流程：
//   resolveInstanceMethod: → forwardingTargetForSelector: → forwardInvocation:

- (id)forwardingTargetForSelector:(SEL)aSelector {
    // 将消息转发给备用对象
    if (aSelector == @selector(someMethod)) {
        return self.backupObject;
    }
    return [super forwardingTargetForSelector:aSelector];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    // 完全控制消息转发
    if ([self.backupObject respondsToSelector:anInvocation.selector]) {
        [anInvocation invokeWithTarget:self.backupObject];
    } else {
        [super forwardInvocation:anInvocation];
    }
}
```

### 3.4 获取类的所有属性和方法

```objc
- (void)logAllProperties {
    unsigned int count = 0;
    objc_property_t *properties = class_copyPropertyList([self class], &count);

    for (int i = 0; i < count; i++) {
        objc_property_t property = properties[i];
        const char *name = property_getName(property);
        const char *attributes = property_getAttributes(property);
        NSLog(@"Property: %s, Attributes: %s", name, attributes);
    }
    free(properties);
}

- (void)logAllMethods {
    unsigned int count = 0;
    Method *methods = class_copyMethodList([self class], &count);

    for (int i = 0; i < count; i++) {
        Method method = methods[i];
        SEL selector = method_getName(method);
        const char *name = sel_getName(selector);
        NSLog(@"Method: %s", name);
    }
    free(methods);
}
```

### 3.5 KVO 底层原理

```objc
// KVO（Key-Value Observing）的 Runtime 实现原理：
//
// ① 动态创建子类：NSKVONotifying_ClassName
// ② 将对象的 isa 指针指向新创建的子类
// ③ 重写被观察属性的 setter 方法
// ④ 重写 class 方法，返回原类名（欺骗外部调用者）

// 验证：
- (void)testKVO {
    NSObject *obj = [[NSObject alloc] init];
    NSLog(@"%s", object_getClassName(obj));  // NSObject

    [obj addObserver:self forKeyPath:@"value" options:NSKeyValueObservingOptionNew context:nil];
    NSLog(@"%s", object_getClassName(obj));  // NSKVONotifying_NSObject
}
```

---

## 参考链接

- [Runtime 方法交换原理](https://blog.csdn.net/weixin_33717298/article/details/91370147)
- [Objective-C Runtime 官方文档](https://developer.apple.com/documentation/objectivec/objective-c_runtime)
