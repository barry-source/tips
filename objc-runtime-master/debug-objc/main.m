//
//  main.m
//  debug-objc
//
//  Created by Closure on 2018/12/4.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "debug-objc-Bridging-Header.h"


int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        Class obj = [NSObject class];

        object_getClass(obj);
    }
    return 0;
}
