//
//  main.m
//  KCObjcBuild
//
//  Created by cooci on 2021/1/5.


// KC 重磅提示 调试工程很重要 源码直观就是爽
// ⚠️编译调试不能过: 请你检查以下几小点⚠️
// ①: enable hardened runtime -> NO
// ②: build phase -> denpendenice -> objc
// 爽了之后,还来一个 👍

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <malloc/malloc.h>
#import "SATest.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        NSObject *obj = [NSObject new];
        __weak NSObject *o1 = obj;
        __weak NSObject *o2 = obj;
        NSLog(@"%p-%p-%p", obj, &o1, &o2);
        
        NSNumber *number1 = @4;
        NSNumber *number2 = @5;
        NSNumber *number3 = @(0xFFFFFFFFFFFFFFF);
        
//        [number1 setValue:@5 forKey: @"stringValue"];
        number1 = @5;
        
//        NSLog(@"%d %d %d", isTaggedPointer(number1), isTaggedPointer(number2), isTaggedPointer(number3));
        NSLog(@"%p %p %p", number1, number2, number3);
//        // insert code here...
//        NSLog(@"Hello, World!");
//
//        NSObject *objc = [NSObject alloc];
//        //SATest *objc1 = [[SATest alloc] init];
//        //SATest *objc2 = [SATest new];
//
//        NSLog(@"objc对象类型占用的内存大小：%lu",sizeof(objc));
//        NSLog(@"objc对象实际占用的内存大小：%lu",class_getInstanceSize([objc class]));
//        NSLog(@"objc对象实际分配的内存大小：%lu",malloc_size((__bridge const void*)(objc)));
        
        
    }
    return 0;
}
