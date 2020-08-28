> KVO(Key-value observing)提供一种在其它对象的属性更改时通知观察它的对象的一种机制。当然它和通知都是[观察者模式](https://www.jianshu.com/p/eab7dcfd8c9a)的实现，只是侧重点不同而已。KVO在模型和控制器之前的交互起着非常重要的作用。在`OSX`平台中，控制器层的绑定技术很依赖`KVO`。可以利用`KVO`观察简单属性，一对一关系的属性和一对多关系的属性。下面会一一展示三种情况

[Demo](https://github.com/barry-source/tips/tree/master/KVO)

## 一、基本用法

> 场景：Person代表一个人，Account代表这个人在银行的账户。当Account中对应属性发生改变的时候会通知Person

```Objective-C
@implementation Person
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSLog(@"%@", change);
}
@end

@interface Account : NSObject

@property (nonatomic, assign) double balance; //余额
@property (nonatomic, assign) double interestRate; //利率

@end

```
添加观察者

```Objective-C
- (void)basicUse {
    self.person = [[Person alloc] init];
    self.account = [[Account alloc] init];
    self.account.balance = 0.0;
    self.account.interestRate = 2.01;
    [self.account addObserver:self.person forKeyPath:@"balance" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
}
//最后移除观察者
- (void)dealloc {
    [self.account removeObserver:self.person forKeyPath:"balance" context:nil];
}
```

#### 1.1、注册成为观察者
被注册的对象发消息`addObserver:forKeyPath:options:context:`
其中
**options**
（指定选项按位或操作）会影响通知中提供的更改字典的内容以及生成通知的方式。options的配置选项：
`NSKeyValueObservingOptionOld`表示获取旧值，
`NSKeyValueObservingOptionNew`表示获取新值，
`NSKeyValueObservingOptionInitial`表示在添加观察的时候就立马响应一个回调，
`NSKeyValueObservingOptionPrior`表示在被观察属性变化前后都回调一次

**Context**
正常情况下可以指定为nil，可以通过`observeValueForKeyPath:ofObject:change:context:`中的key path来判断监听的哪个属性发生的改变，但是有父类和子类都监听同一属性的时候会出现问题，利用`key path`是无法区分的。所以一种更安全，更可扩展的方法是使用`context`来确保您收到的通知来自您的观察者而不是父类。

#### 1.2、接收通知
通知的接收主要是`observeValueForKeyPath:ofObject:change:context:`这个方法。
```Objective-C
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (context == PersonAccountBalanceContext) {
        NSLog(@"PersonAccountBalanceContext");
    } else if (context == PersonAccountInterestRateContext) {
        NSLog(@"PersonAccountInterestRateContext");
    } else {
        //因为没有对象处理这个消息会抛出一个NSInternalInconsistencyException异常
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}
```
- 如果调用super，这个消息会抛出一个NSInternalInconsistencyException异常。
- 另外这个方法不会对被观察的对象(方法调用者)，观察的对象(observer)和context作强引用操作，所以在适当的时候要自己确保相应的对象必须存在。
#### 1.3、移除观察者
在观察者不需要监听属性变化的时候要确保观察者一定被移除，否则会造成crash
移除观察者要记住以下三点：
- 未注册观察者，但是使用了remove操作会抛出NSRangeException异常。所以在移除前一定要确保注册了观察者。再者可以通过try/catch进行安全的移除，在抛出异常时候可以进行相应的操作。
- 观察者在dealloc的时候不会自己移除自己，所以必须手动移除，但是被观察的对象的属性在发生改变的时候一定要确保观察者是存在的，否则会触发一个内存异常（memory access exception）
- NSKeyValueObserving没有提供对象是否是观察者或者是否正在被观察这样的属性所以要确保add和remove操作必须成对且有序的操作.apple提供的一个正常的流程是在init 或 viewDidLoad里注册观察者，在dealloc里移除观察者

#### 1.4、观察List（ordered, unOrdered）

核心示例如下：

```

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    // 无法监听array的属性
    //    [self.array addObserver:self forKeyPath:@"count" options:(NSKeyValueObservingOptionNew) context:nil];

    // 设置了NSKeyValueObservingOptionInitial 之后就会立即触发了一个NSKeyValueChangeSetting类型的通知
    [self addObserver:self forKeyPath:@"array" options: NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld | NSKeyValueObservingOptionInitial context:nil];
}

//typedef NS_ENUM(NSUInteger, NSKeyValueChange) {
//    NSKeyValueChangeSetting = 1,
//    NSKeyValueChangeInsertion = 2,
//    NSKeyValueChangeRemoval = 3,
//    NSKeyValueChangeReplacement = 4,
//};

- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSKeyValueChangeKey, id> *)change context:(nullable void *)context {
    NSInteger kind = [change[@"kind"] integerValue];
    switch (kind) {
        case NSKeyValueChangeSetting:
            NSLog(@"NSKeyValueChangeSetting");
            break;
        case NSKeyValueChangeInsertion:
            NSLog(@"NSKeyValueChangeInsertion");
            break;
        case NSKeyValueChangeRemoval:
            NSLog(@"NSKeyValueChangeRemoval");
            break;
        case NSKeyValueChangeReplacement:
            NSLog(@"NSKeyValueChangeReplacement");
            break;
    }
    NSLog(@"%@", change);
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    static NSInteger i = 0;
    //##### 注： 数组一定要通过这种方法取出，否则不会触发通知
    NSMutableArray *tempArray = [self mutableArrayValueForKey:@"array"];
    switch (i % 4) { // add
        case 0:
            [tempArray addObject:@"1"];
            break;
        case 1:  // replace
            [tempArray replaceObjectAtIndex:0 withObject:@"2"];
            break;
        case 2: // remove
            [tempArray removeObjectAtIndex:0];
            break;
        case 3:
            [tempArray removeAllObjects]; // 不会触发通知
            break;
        default:
            break;
    }
    i ++;
}

@end

```
其它的序列如NSMutableSet, NSMutableOrderedSet 类似，只不过取值方式一一样

- NSMutableArray -------> `mutableArrayValueForKey`
- NSMutableSet -------> `mutableSetValueForKey`
- NSMutableOrderedSet -------> `mutableOrderedSetValueForKey`

## 二、手动干预观察流程

#### 2.1、使某一属性只有在新值和旧值不相同时发通知
```Objective-C
+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey {
    BOOL automatic = NO;
    if ([theKey isEqualToString:@"balance"]) {
        automatic = NO;
    } else {
        automatic = [super automaticallyNotifiesObserversForKey:theKey];
    }
    return automatic;
}
- (void)setBalance:(double)balance {
    if (_balance != balance) {
        [self willChangeValueForKey:@"balance"];
        _balance = balance;
        [self didChangeValueForKey:@"balance"];
    }
}
```

#### 2.2、更改次数的统计
```Objective-C
//统计更改的次数，只有balance改变才触发itemChanged
- (void)setBalance:(double)balance {
    [self willChangeValueForKey:@"itemChanged"];
    _balance = balance;
    _itemChanged ++;
    [self didChangeValueForKey:@"itemChanged"];
}

//禁用itemChanged的通知但是可以手动触发
+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey {
    BOOL automatic = NO;
    if ([theKey isEqualToString:@"itemChanged"]) {
        automatic = NO;
    } else {
        automatic = [super automaticallyNotifiesObserversForKey:theKey];
    }
    return automatic;
}
```
#### 2.3、对于一对多属性的更改
```Objective-C
- (void)removeTransactionsAtIndexes:(NSIndexSet *)indexes {

[self willChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"transactions"];

// Remove the transaction objects at the specified indexes.
[self.transactions removeObjectsAtIndexes:indexes];

[self didChange:NSKeyValueChangeRemoval valuesAtIndexes:indexes forKey:@"transactions"];

}
```
除了删除操作，还有其它的一些操作
```Objective-C
typedef NS_ENUM(NSUInteger, NSKeyValueChange) {
    NSKeyValueChangeSetting = 1,
    NSKeyValueChangeInsertion = 2,
    NSKeyValueChangeRemoval = 3,
    NSKeyValueChangeReplacement = 4,
};
```
## 三、键依赖
在许多情况下，一个属性的值取决于另一个对象中的一个或多个其他属性的值。 如果一个属性的值发生更改，则还应通知依赖这个属性的值的属性进行更改。
#### 3.1、To-one Relationships 的属性依赖
下面的例子中监听firstName, lastName和fullName，当firstName, lastName中的任一一个值更改时都会触发fullName更改的通知
```Objective-C

// 只要 firstName 和 lastName 有一个改变就会触发fullName的通知
// 方式 1
+ (NSSet<NSString *> *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    if ([key isEqualToString:@"fullName"]) {
        NSArray *affectingKeys = @[@"lastName", @"firstName"];
        keyPaths = [keyPaths setByAddingObjectsFromArray:affectingKeys];
    }
    return keyPaths;
}

- (NSString *)fullName {
    return [NSString stringWithFormat:@"%@ %@",self.firstName, self.lastName];
}
```
或者可以利用简便的方法
```Objective-C

- (NSString *)fullName {
    return [NSString stringWithFormat:@"%@ %@",self.firstName, self.lastName];
}

// 只要 firstName 和 lastName 有一个改变就会触发fullName的通知
// 方式 2
+ (NSSet<NSString *> *)keyPathsForValuesAffectingFullName {
    return [NSSet setWithObjects:@"lastName", @"firstName", nil];
}
```
#### 3.2、To-many Relationships 的属性依赖
如果某个属性的值依赖一个数组中的每个元素的话，可以进行下面的操作。总共的薪水依赖每个的雇用者的薪资的总和
```Objective-C
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == totalSalaryContext) {
        [self updateTotalSalary];
    }
    else
        // deal with other observations and/or invoke super...
    }
}
- (void)updateTotalSalary {
    [self setTotalSalary:[self valueForKeyPath:@"employees.@sum.salary"]];
}

- (void)setTotalSalary:(NSNumber *)newTotalSalary {
    if (totalSalary != newTotalSalary) {
        [self willChangeValueForKey:@"totalSalary"];
        _totalSalary = newTotalSalary;
        [self didChangeValueForKey:@"totalSalary"];
    }
}

- (NSNumber *)totalSalary {
    return _totalSalary;
}

```
## 四、KVO原理

KVO是通过`isa-swizzling`技术实现的([官方文档](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/KeyValueObserving/Articles/KVOImplementation.html#//apple_ref/doc/uid/20002307-BAJEAIEE)就是一句话概括的)。具体来说就是在运行时动态创建一个中间类对象，这个中间类对象是原类对象的子类(即`superClass`指针指向原来的类对象)，并动态修改当前实例对象的`isa`指向中间类对象。并且将class方法重写，返回原类对象的`Class`。所以苹果建议在开发中不应该依赖`isa`指针，而是通过class实例方法来获取实例对象的类型。
测试代码

.h文件
```Objective-C
@interface DeepSearch : NSObject
    @property int x;
    @property int y;
    @property int z;

    + (NSArray *)ClassMethodNames:(Class) c;
    + (void)PrintDescription:(NSString *)name obj:(id) obj;
@end

```
.m文件
```Objective-C
#import "DeepSearch.h"
#import <objc/runtime.h>

struct temp_objc_class {
    Class _Nonnull isa;
    Class superclass;
};

@implementation DeepSearch

//获取当前类所有的实例方法
+ (NSArray *)ClassMethodNames:(Class)c {
    NSMutableArray *array = [NSMutableArray array];

    unsigned int methodCount = 0;
    Method *methodList = class_copyMethodList(c, &methodCount);
    unsigned int i;
    for(i = 0; i < methodCount; i++)
        [array addObject: NSStringFromSelector(method_getName(methodList[i]))];
    free(methodList);

    return array;
}


+ (void)PrintDescription:(NSString *)name obj:(id) obj {

    struct temp_objc_class *c = (__bridge struct temp_objc_class *)(obj);

    NSString *str = [NSString stringWithFormat:
    @"%@: \n\t当前对象 --- %@\n\tNSObject class --- %s\n\tlibobjc class --- %s\n\timplements methods --- <%@>\t\n%@",
    name,
    obj,
    class_getName([obj class]),
    class_getName(c->isa),
    [[self ClassMethodNames:c->isa] componentsJoinedByString:@", "],
    [[self ClassMethodNames:c->superclass] componentsJoinedByString:@", "]];
    printf("%s\n", [str UTF8String]);
}

@end

```
调用
```Objective-C
- (void)deepSearchTest {
    DeepSearch *x = [[DeepSearch alloc] init];
    DeepSearch *y = [[DeepSearch alloc] init];
    DeepSearch *xy = [[DeepSearch alloc] init];
    DeepSearch *control = [[DeepSearch alloc] init];

    [x addObserver:x forKeyPath:@"x" options:0 context:NULL];
    [xy addObserver:xy forKeyPath:@"x" options:0 context:NULL];
    [y addObserver:y forKeyPath:@"y" options:0 context:NULL];
    [xy addObserver:xy forKeyPath:@"y" options:0 context:NULL];

    [DeepSearch PrintDescription:@"control" obj:control];
    [DeepSearch PrintDescription:@"x" obj:x];
    [DeepSearch PrintDescription:@"y" obj:y];
    [DeepSearch PrintDescription:@"xy" obj:xy];

    printf("使用NSObject方法, 正常的 setX 地址: is %p, 重写 setX后的地址: is %p\n",
        [control methodForSelector:@selector(setX:)],
        [x methodForSelector:@selector(setX:)]);
    printf("使用libobjc方法, 正常的 setX 地址: is %p, 重写 setX后的地址: is %p\n",
        method_getImplementation(class_getInstanceMethod(object_getClass(control), @selector(setX:))),
        method_getImplementation(class_getInstanceMethod(object_getClass(x), @selector(setX:))));
}
```
然后创建了4个DeepSearch实例，每一个都使用了不同的观察方式。`x`实例有一个观察者`x`观察`key x`，`y`实例有一个观察者`y观察`key y , `xy`实例有一个观察者观察`key x`和`y`。为了做比较，`key z`没有观察者。最后`control`实例没有任何观察者。
下面打印的结果：
```Objective-C
control: 
    当前对象 --- <DeepSearch: 0x6000017263c0>
    class_getName([obj class]) --- DeepSearch
    class_getName(c->isa) --- DeepSearch
    implements methods --- <setZ:, x, setX:, y, setY:, z>
    父类方法 --- _isMKClusterAnnotation, ...中间方法太多省略了..., isFault
    x: 
    当前对象 --- <DeepSearch: 0x600001726420>
    class_getName([obj class]) --- DeepSearch
    class_getName(c->isa) --- NSKVONotifying_DeepSearch
    implements methods --- <setY:, setX:, class, dealloc, _isKVOA>
    父类方法 --- setZ:, x, setX:, y, setY:, z
y: 
    当前对象 --- <DeepSearch: 0x600001726400>
    class_getName([obj class]) --- DeepSearch
    class_getName(c->isa) --- NSKVONotifying_DeepSearch
    implements methods --- <setY:, setX:, class, dealloc, _isKVOA>
    父类方法 --- setZ:, x, setX:, y, setY:, z
xy: 
    当前对象 --- <DeepSearch: 0x6000017263e0>
    class_getName([obj class]) --- DeepSearch
    class_getName(c->isa) --- NSKVONotifying_DeepSearch
    implements methods --- <setY:, setX:, class, dealloc, _isKVOA>
    父类方法 --- setZ:, x, setX:, y, setY:, z
    使用NSObject方法, 正常的 setX 地址: is 0x104e2b850, 重写 setX后的地址: is 0x10518a3d2
    使用libobjc方法, 正常的 setX 地址: is 0x104e2b850, 重写 setX后的地址: is 0x10518a3d2

```
打印结果分析：
- `control` 没有观察任何属性，
    1、通过`class_getName([obj class])`获取的是`DeepSearch`, 而`x`,`y`和`xy`都观察了对象的属性，通过`class_getName([obj class])`,获取的是`NSKVONotifying_DeepSearch`，
    2、`class_getName(c->isa)`指针获取的当前类类对象`control`是`DeepSearch`，而`x`,`y`,`xy`是`NSKVONotifying_DeepSearch`。
    **所以说明确实在运行时动态创建了一个类对象，当前实例对象的`isa`指针指向了新的类对象**。
- `control`通过`[self ClassMethodNames:cSuper->superclass]`获取的父类类对象方法是`NSObject`的方法，而`x`,`y`,`xy`获取的父类类对象的方法是原来的类对象的。**所以说明新创建的类对象的`superclass`指向了旧的类对象**。
- 通过上面的对比发现新创建的类对象重写了`setX`、`setY`、`class`、`dealloc`和`_isKVOA`五个方法，对于没有观察的属性`z`没有被重写。
- 对于`class` 方法重写之后，其发消息获取的对象是旧的类对象，这是apple做了一层掩盖。如果想获取具体的类型可通过函数`object_getClass`。`dealloc`方法处理一些收尾工作。还有一个`_isKVOA`方法，看起来像是一个私有方法。

##  简单总结

![简单总结.jpg](https://upload-images.jianshu.io/upload_images/1846524-56bab2d9ec6ec161.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

demo纯属展示里面的一些细节

[手动实现kvoDemo](https://github.com/tsc000/Exploration/tree/master/OverrideKVO)

[mikeash大神KVO实现](https://github.com/mikeash/MAKVONotificationCenter)

[mikeash大神](https://www.mikeash.com/pyblog/friday-qa-2009-01-23.html)

## 五、KVO缺点
- `-addObserver:forKeyPath:options:context:`不允许添加自定义的`selector`。只能重写 `-observeValueForKeyPath:ofObject:change:context:`来实现相应的操作，如果父类和当前类都观察了同一个属性，如果决定谁来处理通知，这需要自己判断。不像`NSNotificationCenter`，它可以添加自定义的`selector`，所以很容易将一些操作从父类中分离，因为它们用的是不同的`selector`。
- `context`无用
为了解决上一个问题引入了context，通过context可以分离父类和当前的操作。必须保证context是唯一的。这个事实的结果是你不能使用上下文指针来实际保存上下文。
- `-removeObserver:forKeyPath: `没有提供足够的参数。当前根据`context`移除观察者的时候，不确定移除的是父类的还是当类的，或者两个都移除。

可能的面试题：
## 1、KVO的本质是什么？

利用RuntimeAPI动态生成一个子类，并且让instance对象的isa指向这个全新的子类
当修改instance对象的属性时，会调用Foundation的_NSSetXXXValueAndNotify函数
willChangeValueForKey:
父类原来的setter
didChangeValueForKey:
内部会触发监听器（Oberser）的监听方法( observeValueForKeyPath:ofObject:change:context:）

## 2、能不能手动触发KVO？
可以，手动调用willChangeValueForKey:和didChangeValueForKey:

## 3、直接修改成员变量会触发KVO么？

不会

[demo](https://github.com/tsc000/Exploration)


