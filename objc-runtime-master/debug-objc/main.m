//
//  main.m
//  debug-objc
//
//  Created by Closure on 2018/12/4.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "debug-objc-Bridging-Header.h"
#import "Dog.h"
#import "Animal.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        NSObject *obj = [[NSObject alloc] init];
        Animal *animal = [[Animal alloc] init];
        Dog *dog = [[Dog alloc] init];
        
        Class objClass = [obj class];
        Class animalClass = [animal class];
        Class dogClass = [dog class];
        
        Class objMetaClass = object_getClass([NSObject class]);
        Class animalMetaClass = object_getClass([Animal class]);
        Class dogMetaClass = object_getClass([Dog class]);
        
        
        
    }
    return 0;
}
