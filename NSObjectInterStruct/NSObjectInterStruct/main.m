//
//  main.m
//  NSObjectInterStruct
//
//  Created by tongshichao on 2020/8/16.
//  Copyright © 2020 tongshichao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

struct NSObject_IMPL {
    Class isa;
};

// 获取所有的对象
void getObject() {
    //获取实例对象
    NSObject *obj1 = [[NSObject alloc] init];
    NSObject *obj2 = [[NSObject alloc] init];
    //获取类对象
    Class cls1 = object_getClass(obj1);
    Class cls2 = object_getClass(obj2);
    Class cls3 = [obj1 class];
    Class cls4 = [NSObject class];
    //获取元类对象
    Class m1 = object_getClass(cls1);
    Class m2 = object_getClass(cls2);
    NSLog(@"实例对象地址：%p--%p", obj1, obj2);
    NSLog(@"类对象地址：%p--%p--%p--%p", cls1, cls2, cls3, cls4);
    NSLog(@"元类对象地址：%p--%p", m1, m2);
}


int main(int argc, const char * argv[]) {
    @autoreleasepool {
        getObject();
        
        //获取实例对象
        NSObject *obj1 = [[NSObject alloc] init];
        NSObject *obj2 = [[NSObject alloc] init];
        //获取类对象
        Class cls1 = object_getClass(obj1);
        Class cls2 = object_getClass(obj2);
        Class cls3 = [obj1 class];
        Class cls4 = [NSObject class];
        //获取元类对象
        Class m1 = object_getClass(cls1);
        Class m2 = object_getClass(cls2);
        NSLog(@"实例对象地址：%p--%p", obj1, obj2);
        NSLog(@"类对象地址：%p--%p--%p--%p", cls1, cls2, cls3, cls4);
        NSLog(@"元类对象地址：%p--%p", m1, m2);
        
        struct NSObject_IMPL *test = (__bridge struct NSObject_IMPL *)(obj1);
        NSLog(@"%p", test->isa);
    }
    return 0;
}
