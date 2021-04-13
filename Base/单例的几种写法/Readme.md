
# 单例的几种写法

> 单例模式是一种常用的软件设计模式。在它的核心结构中只包含一个被称为单例类的特殊类。通过单例模式可以保证系统中一个类只有一个实例而且该实例易于外界访问，从而方便对实例个数的控制并节约系统资源。如果希望在系统中某个类的对象只能存在一个，单例模式是最好的解决方案。

### 一、只用于单线程（多线程不安全）

```phthon
static Share *_instance = nil;

@implementation Share
//线程不安全
+ (instancetype)shared {
    return [[self alloc] init];
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    if (_instance == nil) {
        _instance = [super allocWithZone:zone];
    }
    return _instance;
}

- (id)copyWithZone:(NSZone *)zone {
    return _instance;
}

- (id)mutableCopyWithZone:(NSZone *)zone {
    return _instance;
}

@end
```

### 二、使用dispatch_once只创建一次 (推荐)

```phthon
static Share *_instance = nil;

@implementation Share

+ (instancetype)shared {
    return [[self alloc] init];
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t oneceToken;
    dispatch_once(&oneceToken, ^{
        _instance = [super allocWithZone:zone];
    });
    return _instance;
}

//为了严谨重写copy mutableCopy
- (id)copyWithZone:(NSZone *)zone {
    return _instance;
}

- (id)mutableCopyWithZone:(NSZone *)zone {
    return _instance;
}

@end
```

### 三、同步锁

```phthon
static Share *_instance = nil;

@implementation Share

+ (instancetype)shared {
    return [[self alloc] init];
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    @synchronized (self) {
        if (_instance == nil) {
            _instance = [super allocWithZone:zone];
        }
    }
    return _instance;
}

- (id)copyWithZone:(NSZone *)zone {
    return _instance;
}

- (id)mutableCopyWithZone:(NSZone *)zone {
    return _instance;
}

@end

```

### 四、同步锁2（前后再次非空判断）

```phthon
static Share *_instance = nil;

@implementation Share

+ (instancetype)shared {
    return [[self alloc] init];
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    if (_instance == nil) {
        @synchronized (self) {
            if (_instance == nil) {
                _instance = [super allocWithZone:zone];
            }
        }
    }
    return _instance;
}

- (id)copyWithZone:(NSZone *)zone {
    return _instance;
}

- (id)mutableCopyWithZone:(NSZone *)zone {
    return _instance;
}
```

### Swift 单例写法


Swift 单例写法比较简单，如下代码所示：

```python
class Singleton {

    static let shared = Singleton()
    
    private init() { 
        // 不要忘记把构造器变成私有
    }
}

let singleton = Singleton.shared
```

swift 中利用let 保证变量只会被赋值一次，是线程安全的，另外swift 中dispatch_once已被废弃
