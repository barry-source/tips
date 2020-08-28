//
//  DeepSearch.m
//  KVO
//
//  Created by Honey on 2019/5/7.
//  Copyright © 2019 Honey. All rights reserved.
//

#import "DeepSearch.h"
#import <objc/runtime.h>

struct temp_objc_class {
    Class _Nonnull isa;
    Class superclass;
};

@implementation DeepSearch

//获取当前类所有的实例方法
+ (NSArray *)ClassMethodNames:(Class)c {
    NSMutableArray *array = [NSMutableArray array];

    unsigned int methodCount = 0;
    Method *methodList = class_copyMethodList(c, &methodCount);
    unsigned int i;
    for(i = 0; i < methodCount; i++)
        [array addObject: NSStringFromSelector(method_getName(methodList[i]))];
    free(methodList);

    return array;
}


+ (void)PrintDescription:(NSString *)name obj:(id) obj {

    struct temp_objc_class *c = (__bridge struct temp_objc_class *)(obj);
    struct temp_objc_class *cSuper = (__bridge struct temp_objc_class *)(c->isa);
    NSString *str = [NSString stringWithFormat:
                     @"%@: \n\t当前对象 --- %@\n\tNSObject class --- %s\n\tlibobjc class --- %s\n\timplements methods --- <%@>\n\t父类方法 --- %@",
                     name,
                     obj,
                     class_getName([obj class]),
                     class_getName(c->isa),
                     [[self ClassMethodNames:c->isa] componentsJoinedByString:@", "],
                     [[self ClassMethodNames:cSuper->superclass] componentsJoinedByString:@", "]];
    printf("%s\n", [str UTF8String]);
}

@end
