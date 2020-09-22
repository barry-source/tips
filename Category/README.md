### 面试题

> Category的实现原理，Category能不能加属性。如果不能，为什么？

> Category中有load方法吗？load方法的调用时机？load 方法能继承吗？

> load、initialize在category中的调用的顺序，以及出现继承时他们之间的调用的过程

> load、initialize的区别，以及它们在category重写的时候的调用的次序。


```Objective-C

/// Animal.h
@interface Animal : NSObject

- (void)run;

@end

/// Animal.m

@implementation Animal

- (void)run {
    NSLog(@"Animal --- run");
}

@end

///  Animal+Function1.h

@interface Animal (Function1) <NSCopying>

@property (nonatomic, assign) NSInteger age;

- (void)animalInstanceMethod;
+ (void)animalClassMethod;

@end

///  Animal+Function1.m

#import "Animal+Function1.h"

@implementation Animal (Function1)

- (void)run {
    NSLog(@"Function1 --- run");
}

- (void)animalInstanceMethod {
    NSLog(@"Function1 --- animalInstanceMethod");
}

+ (void)animalClassMethod {

}

- (NSInteger)age {
    return 10;
}

- (void)setAge:(NSInteger)age {

}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return [Animal new];
}

@end

///  Animal+Function2.h

@interface Animal (Function2)

@end

///  Animal+Function2.m

@implementation Animal (Function2)

- (void)run {
    NSLog(@"Function2 --- run");
}

@end

```
