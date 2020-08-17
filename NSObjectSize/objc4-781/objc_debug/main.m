//
//  main.m
//  objc_debug
//
//  Created by tongshichao on 2020/8/16.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        object_getClass([NSObject class]);
    }
    return 0;
}
