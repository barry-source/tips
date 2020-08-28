//
//  main.m
//  NSObjectInterStruct
//
//  Created by tongshichao on 2020/8/16.
//  Copyright © 2020 tongshichao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "Dog.h"
#import "Animal.h"
#import "DebugClass.h"

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


void isaTesByTerinal() {
    // 0x00007ffffffffff8ULL
    NSObject *obj = [[NSObject alloc] init];
    Animal *animal = [[Animal alloc] init];
    Dog *dog = [[Dog alloc] init];
    
    Class objOrinalClass = [obj class];
    Class animalOrinalClass = [animal class];
    Class dogOrinalClass = [dog class];

    Class objOrinalMetaClass = object_getClass([NSObject class]);
    Class animalOrinalMetaClass = object_getClass([Animal class]);
    Class dogOrinalMetaClass = object_getClass([Dog class]);
    
    
    debug_objc_class *objClass = (__bridge struct debug_objc_class *)(objOrinalClass);
    debug_objc_class *animalClass = (__bridge struct debug_objc_class *)(animalOrinalClass);
    debug_objc_class *dogClass = (__bridge struct debug_objc_class *)(dogOrinalClass);

    debug_objc_class *objMetaClass = (__bridge struct debug_objc_class *)(objOrinalMetaClass);
    debug_objc_class *animalMetaClass = (__bridge struct debug_objc_class *)(animalOrinalMetaClass);
    debug_objc_class *dogMetaClass = (__bridge struct debug_objc_class *)(dogOrinalMetaClass);

    
    class_rw_t *animalClassData = animalClass->data();
    // Direct access to Objective-C's isa is deprecated in favor of object_getClass()
    NSLog(@"%p", &(objClass->isa));
    NSLog(@"adf");
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
//        getObject();
        isaTesByTerinal();
        
//        NSObject *obj = [[NSObject alloc] init];
//        Animal *animal = [[Animal alloc] init];
//        Dog *dog = [[Dog alloc] init];
//
//        Class objOrinalClass = [obj class];
//        Class animalOrinalClass = [animal class];
//        Class dogOrinalClass = [dog class];
//
//        Class objOrinalMetaClass = object_getClass([NSObject class]);
//        Class animalOrinalMetaClass = object_getClass([Animal class]);
//        Class dogOrinalMetaClass = object_getClass([Dog class]);
//
//        debug_objc_class *objClass = (__bridge struct debug_objc_class *)(objOrinalClass);
//        debug_objc_class *animalClass = (__bridge struct debug_objc_class *)(animalOrinalClass);
//        debug_objc_class *dogClass = (__bridge struct debug_objc_class *)(dogOrinalClass);
//
//        debug_objc_class *objMetaClass = (__bridge struct debug_objc_class *)(objOrinalMetaClass);
//        debug_objc_class *animalMetaClass = (__bridge struct debug_objc_class *)(animalOrinalMetaClass);
//        debug_objc_class *dogMetaClass = (__bridge struct debug_objc_class *)(dogOrinalMetaClass);
//
//
//        class_rw_t *objClassData = objClass->data();
//        class_rw_t *animalClassData = animalClass->data();
//        class_rw_t *dogClassData = dogClass->data();
//        // 0x00007ffffffffff8ULL
//        NSObject *animal = [[Animal alloc] init];
//        debug_objc_class *animalClass = (__bridge struct debug_objc_class *)([animal class]);
//        debug_objc_class *animalMetaClass = (__bridge struct debug_objc_class *)(object_getClass([Animal class]));
//
    
//        debug_objc_class *objMetaClass = objClass->metaClass();
//        debug_objc_class *animalMetaClass = animalClass->metaClass();
//        debug_objc_class *dogMetaClass = dogClass->metaClass();
//

        
//        NSObject *object = [[NSObject alloc] init];
//        Person *person = [[Person alloc] init];
//        Student *student = [[Student alloc] init];
//
//        xx_objc_class *objectClass = (__bridge xx_objc_class *)[object class];
//        xx_objc_class *personClass = (__bridge xx_objc_class *)[person class];
//        xx_objc_class *studentClass = (__bridge xx_objc_class *)[student class];
//
//        xx_objc_class *objectMetaClass = objectClass->metaClass();
//        xx_objc_class *personMetaClass = personClass->metaClass();
//        xx_objc_class *studentMetaClass = studentClass->metaClass();
//
//        class_rw_t *objectClassData = objectClass->data();
//        class_rw_t *personClassData = personClass->data();
//        class_rw_t *studentClassData = studentClass->data();
//
//        class_rw_t *objectMetaClassData = objectMetaClass->data();
//        class_rw_t *personMetaClassData = personMetaClass->data();
//        class_rw_t *studentMetaClassData = studentMetaClass->data();
//
//        // 0x00007ffffffffff8
//        NSLog(@"%p %p %p %p %p %p",  objectClassData, personClassData, studentClassData,
//              objectMetaClassData, personMetaClassData, studentMetaClassData);
        
    }
    return 0;
}
