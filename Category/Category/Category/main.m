//
//  main.m
//  Category
//
//  Created by TSC on 2020/9/16.
//  Copyright © 2020 TSC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Animal.h"
#import "Animal+Function1.h"
#import "Animal+Function2.h"

struct objc_selector
{
    union
    {
        const char *name;
        uintptr_t index;
    };
    /**
     * The Objective-C type encoding of the message identified by this selector.
     */
    const char * types;
};

//typedef void (*IMP)(void /* id, SEL, ... */ );


typedef void (*Test)(int);

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        Animal *animal = [Animal new];

        [Animal animalClassMethod];
        // 获取selector
        SEL selector = @selector(animalInstanceMethod);
        // 获取animal中对应selector的方法实现
        IMP imp = [animal methodForSelector: selector];
        // 构造一个和IMP一样的函数指针，参数必须包括id和SEL两个参数,少则报错，多不影响
        void (*func)(id, SEL) = (void *)imp;
        // 下面故意将两个参数的值修改成其它
        func(@"test", @selector(run));
        
//        struct objc_selector *s = {{"firstVar"}, 100};
//        NSLog(@"%s", s);
//        /// 输出结果：firstVar
//
//        SEL selector = @selector(animalClassMethod);
//        NSLog(@"%s", selector);
//        /// 输出结果：animalClassMethod
    }
    return 0;
}
