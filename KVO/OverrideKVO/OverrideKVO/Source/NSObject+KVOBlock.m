//
//  NSObject+KVOBlock.m
//  OverrideKVO
//
//  Created by Honey on 2019/5/8.
//  Copyright © 2019 Honey. All rights reserved.
//

#import "NSObject+KVOBlock.h"
#import <objc/runtime.h>
#import <objc/message.h>

static NSString *const kKVOClassPrefix = @"KVOClass_";
static NSString *const kKVOAssociatedObservers = @"KVOAssociatedObservers";

@interface ObservationTool : NSObject

@property (nonatomic, weak) NSObject *observer;
@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) KVOBlock block;

@end

@implementation ObservationTool

- (instancetype)initWithObserver:(NSObject *)observer Key:(NSString *)key block:(KVOBlock)block
{
    self = [super init];
    if (self) {
        _observer = observer;
        _key = key;
        _block = block;
    }
    return self;
}

//根据getter获取相应的setter,因为对于一个key就相应于getter的方法名
+ (NSString *)setterByGetter: (NSString *)getter {
    if (getter.length <= 0) return nil;
    NSString *firstCharacter = [[getter substringToIndex:1] uppercaseString];
    NSString *remainingString = [getter substringFromIndex:1];
    return [NSString stringWithFormat:@"set%@%@:", firstCharacter, remainingString];
}

+ (NSString *)getterBySetter: (NSString *)setter {
    if (setter.length <= 0 || ![setter hasPrefix:@"set"] || ![setter hasSuffix:@":"]) {
        return nil;
    }
    NSRange range = NSMakeRange(3, setter.length - 4);
    NSString *key = [setter substringWithRange:range];
    NSString *firstLetter = [[key substringToIndex:1] lowercaseString];
    key = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1)
                                       withString:firstLetter];
    return key;
}

@end

static void kvo_setter(id self, SEL _cmd, id newValue)
{
    NSString *setterName = NSStringFromSelector(_cmd);
    NSString *getterName = [ObservationTool getterBySetter:setterName];
    if (!getterName) {
        [NSException exceptionWithName:NSInvalidArgumentException reason:@"not found" userInfo:nil];
        return;
    }

    id oldValue = [self valueForKey:getterName];

    //调用super方法
    struct objc_super superclazz = {
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(self))
    };
    void (*objc_msgSendSuperCasted)(void *, SEL, id) = (void *)objc_msgSendSuper;
    objc_msgSendSuperCasted(&superclazz, _cmd, newValue);

    //查找相应的Observer
    NSMutableArray *observers = objc_getAssociatedObject(self, (__bridge const void *)(kKVOAssociatedObservers));
    for (ObservationTool *each in observers) {
        if ([each.key isEqualToString:getterName]) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                each.block(self, getterName, oldValue, newValue);
            });
        }
    }
}

static Class kvo_class(id self, SEL _cmd) {
    return class_getSuperclass(object_getClass(self));
}

@implementation NSObject (KVOBlock)

- (void)addObserver:(NSObject *)observer forKey:(NSString *)key options:(NSKeyValueObservingOptions)options block:(KVOBlock)block {
    // 根据key获取相应的setter方法，不成功直接返回.因为没有setter方法没有办法进行重写进而实现kvo
    SEL setterSel = NSSelectorFromString([ObservationTool setterByGetter:key]);
    Method setterMethod = class_getInstanceMethod([self class], setterSel);
    if (!setterMethod) {
        [NSException exceptionWithName:NSInvalidArgumentException reason:@"not found" userInfo:nil];
        return;
    }
    //判断当前实例的isa指针指向的类对象是否已经是创建的新类对象，如果不是重新创建，并修改isa指针和新类对象的superclass指针
    Class currentClass = object_getClass(self);
    NSString *currentClassName = NSStringFromClass(currentClass);
    if (![currentClassName hasPrefix:kKVOClassPrefix]) {
        currentClass = [self fakeNewClassByOriginalClassName:currentClassName instance:self];
        //设置一个对象的class，也即更新对象的isa指针
        object_setClass(self, currentClass);
    }

    if (![self hasSelector:setterSel]) {
        const char *types = method_getTypeEncoding(setterMethod);
        class_addMethod(currentClass, setterSel, (IMP)kvo_setter, types);
    }

    ObservationTool *tool = [[ObservationTool alloc] initWithObserver:observer Key:key block:block];
    NSMutableArray *observers = objc_getAssociatedObject(self, (__bridge const void *)(kKVOAssociatedObservers));
    if (!observers) {
        observers = [NSMutableArray array];
        objc_setAssociatedObject(self, (__bridge const void *)(kKVOAssociatedObservers), observers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [observers addObject:tool];
}

- (void)removeObserver:(NSObject *)observer forKey:(NSString *)key {
    NSMutableArray* observers = objc_getAssociatedObject(self, (__bridge const void *)(kKVOAssociatedObservers));

    ObservationTool *infoToRemove;
    for (ObservationTool* info in observers) {
        if (info.observer == observer && [info.key isEqual:key]) {
            infoToRemove = info;
            break;
        }
    }

    [observers removeObject:infoToRemove];
}

- (Class)fakeNewClassByOriginalClassName:(NSString *)originalClassName instance:(id)instance {
    NSString *newClassName = [kKVOClassPrefix stringByAppendingString:originalClassName];
    Class newClass = NSClassFromString(newClassName);
    //如果已经存在则直接返回，因为已经创建过，并设置了isa指针
    if (newClass) { return newClass; }

    Class originalClass = object_getClass(instance);
    Method classMethod = class_getInstanceMethod(originalClass, @selector(class));
    const char *classTypeEncoding = method_getTypeEncoding(classMethod);
    //创建新类对象并设置superclass指针
    newClass = objc_allocateClassPair(originalClass, newClassName.UTF8String, 0);
    class_addMethod(newClass, @selector(class), (IMP)kvo_class, classTypeEncoding);
    objc_registerClassPair(newClass);
    return newClass;
}

- (BOOL)hasSelector:(SEL)selector {
    Class class = object_getClass(self);
    unsigned int methodCount = 0;
    Method* methodList = class_copyMethodList(class, &methodCount);
    for (unsigned int i = 0; i < methodCount; i++) {
        SEL thisSelector = method_getName(methodList[i]);
        if (thisSelector == selector) {
            free(methodList);
            return YES;
        }
    }
    free(methodList);
    return NO;
}


@end
