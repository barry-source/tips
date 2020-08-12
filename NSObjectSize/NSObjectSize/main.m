//
//  main.m
//  NSObjectSize
//
//  Created by tongshichao on 2020/8/11.
//  Copyright © 2020 tongshichao. All rights reserved.
//

/// xcrun -sdk iphoneos clang -arch armv7 -rewrite-objc main.m -o main32.cpp
/// xcrun -sdk iphoneos clang -arch arm64 -rewrite-objc main.m -o main_simulator64.cpp
/// xcrun -sdk iphonesimulator13.5 clang -arch i386 -rewrite-objc main.m -o main_simulator64.cpp

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <malloc/malloc.h>


@interface OCObject : NSObject
@end

@implementation OCObject

@end


int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSObject *obj = [[NSObject alloc] init];
        NSLog(@"%zd", class_getInstanceSize([obj class]));
        NSLog(@"%zd", malloc_size((__bridge const void *)(obj)));
    }
    return 0;
}
