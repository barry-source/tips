//
//  main.m
//  debug-objc
//
//  Created by Closure on 2018/12/4.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

int main(int argc, const char * argv[]) {
    @autoreleasepool {

        // insert code here...
        object_getClass([NSObject class]);
    }
    return 0;
}
