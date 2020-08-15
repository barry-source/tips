//
//  main.m
//  MemorySize
//
//  Created by tongshichao on 2020/8/14.
//  Copyright © 2020 tongshichao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TestObject.h"
#import <objc/runtime.h>
#import <malloc/malloc.h>

// 对齐原则：
//1、数据成员对齐规则：结构体的首个数据成员放在偏移量为0的地方，后序的数据成员偏移量为 #pragma pack(n) 指定的数据 n 和数据成员占用字节大小的最小值的整数倍，少则补齐.
//2、结构体中包含结构体，该结构体成“自身数据”类型占用的大小为结构体中成员类型占用最大字节数。
//3、结构体的整体对齐规则：结构体在按照规则 1 对齐之后,结构体本身也要对齐。最终大小为 #pragma pack(n) 指定的数据 n 和结构体中成员占用的最大字节数中最小值的整数倍，少则补齐.

void pack1test() {
    #pragma pack(1)
    struct CustomType {
        //1、数据成员对齐规则
        char a;     // 占用空间大小1 = 1, 偏移量为 1 的倍数, 偏移量为 0, 存放空间位置 [0]
        short b;    // 占用空间大小2 > 1, 偏移量为 1 的倍数, 偏移量为 1, 存放空间位置 [1, 2]
        char c;     // 占用空间大小1 = 1, 偏移量为 1 的倍数, 偏移量为 3, 存放空间位置 [3]
        int d;      // 占用空间大小4 > 1, 偏移量为 1 的倍数, 偏移量为 4, 存放空间位置 [4, 7]
        char e;     // 占用空间大小1 = 1, 偏移量为 1 的倍数, 偏移量为 8, 存放空间位置 [8]
        // 数据成员总共占用空间为 [0, 8] 共9个字节
    };
    //3、结构体的整体对齐规则: min(1, max(short, char, int)) = 1, 9 是 1 的整数倍，所以结构体最终占用空间为9个字节。
    #pragma pack()
    struct CustomType a;
    NSLog(@"%zd", sizeof(a));
}

void pack2test() {
    #pragma pack(2)
    struct CustomType {
        //1、数据成员对齐规则
        char a;     // 占用空间大小1 < 2, 偏移量为 1 的倍数, 偏移量为 0,  存放空间位置 [0]
        short b;    // 占用空间大小2 = 2, 偏移量为 2 的倍数, 偏移量为 2,  存放空间位置 [2, 3]
        char c;     // 占用空间大小1 < 2, 偏移量为 1 的倍数, 偏移量为 4， 存放空间位置 [4]
        int d;      // 占用空间大小4 > 2, 偏移量为 2 的倍数, 偏移量为 6， 存放空间位置 [6, 9]
        char e;     // 占用空间大小1 < 2, 偏移量为 1 的倍数, 偏移量为 10，存放空间位置 [10]
        // 数据成员总共占用空间为 [0, 10] 共11个字节
    };
    //3、结构体的整体对齐规则: min(2, max(short, char, int)) = 2, 11 不是 2 的整数倍，空间大小变为 12，所以结构体最终占用空间为 12 个字节。
    #pragma pack()
    struct CustomType a;
    NSLog(@"%zd", sizeof(a));
}

void pack4test() {
    #pragma pack(4)
    struct CustomType {
        //1、数据成员对齐规则
        char a;     // 占用空间大小1 < 4, 偏移量为 1 的倍数, 偏移量为 0,  存放空间位置 [0]
        short b;    // 占用空间大小2 < 4, 偏移量为 2 的倍数, 偏移量为 2,  存放空间位置 [2, 3]
        char c;     // 占用空间大小1 < 4, 偏移量为 1 的倍数, 偏移量为 4,  存放空间位置 [4]
        int d;      // 占用空间大小4 = 4, 偏移量为 4 的倍数, 偏移量为 8,  存放空间位置 [8, 11]
        char e;     // 占用空间大小1 < 4, 偏移量为 1 的倍数, 偏移量为 12, 存放空间位置 [12]
        // 数据成员总共占用空间为 [0, 12] 共13个字节
    };
    //3、结构体的整体对齐规则: min(4, max(short, char, int)) = 4, 13 不是 4 的整数倍，空间大小变为 16，所以结构体最终占用空间为 16 个字节。
    #pragma pack()
    struct CustomType a;
    NSLog(@"%zd", sizeof(a));
}

void pack8test() {
    #pragma pack(8)
    struct CustomType {
        //1、数据成员对齐规则
        char a;     // 占用空间大小1 < 8, 偏移量为 1 的倍数, 偏移量为 0,  存放空间位置 [0]
        short b;    // 占用空间大小2 < 8, 偏移量为 2 的倍数, 偏移量为 2,  存放空间位置 [2, 3]
        char c;     // 占用空间大小1 < 8, 偏移量为 1 的倍数, 偏移量为 4,  存放空间位置 [4]
        int d;      // 占用空间大小4 < 8, 偏移量为 4 的倍数, 偏移量为 8,  存放空间位置 [8, 11]
        char e;     // 占用空间大小1 < 8, 偏移量为 1 的倍数, 偏移量为 12, 存放空间位置 [12]
        // 数据成员总共占用空间为 [0, 12] 共13个字节
    };
    //3、结构体的整体对齐规则: min(8, max(short, char, int)) = 4, 13 不是 4 的整数倍，空间大小变为 16，所以结构体最终占用空间为 16 个字节。
    #pragma pack()
    struct CustomType a;
    NSLog(@"%zd", sizeof(a));
}

void pack4StructTest() {
#pragma pack(4)
    struct CustomType {
        //1、数据成员对齐规则
        char a;                 // 占用空间大小1 < 4, 偏移量为 1 的倍数, 偏移量为 0,  存放空间位置 [0]
        short b;                // 占用空间大小2 < 4, 偏移量为 2 的倍数, 偏移量为 2,  存放空间位置 [2, 3]
        struct InnerCustomType {
            //1、数据成员对齐规则
            int a1;             // 占用空间大小4 = 4, 偏移量为 4 的倍数, 偏移量为 4,   存放空间位置 [4, 7]
            char b1;            // 占用空间大小1 < 4, 偏移量为 1 的倍数, 偏移量为 8,   存放空间位置 [8]
            short c1;           // 占用空间大小2 < 4, 偏移量为 2 的倍数, 偏移量为 10,  存放空间位置 [10, 11]
            char d1;            // 占用空间大小1 < 4, 偏移量为 1 的倍数, 偏移量为 12,  存放空间位置 [12]
            // InnerCustomType 数据成员总共占用空间为 [4, 12] 共9个字节
            //3、结构体的整体对齐规则: min(4, max(short, char, int)) = 4, 9 不是 4 的整数倍，InnerCustomType空间大小变为 12，所以InnerCustomType结构体最终占用空间为 12 个字节, 范围[4, 15]
        } c;
        int d;                  // 占用空间大小4 = 4, 偏移量为 4 的倍数, 偏移量为 16,  存放空间位置 [16, 19]
        char e;                 // 占用空间大小1 < 4, 偏移量为 1 的倍数, 偏移量为 20,  存放空间位置 [20]
        // CustomType结构体数据成员总共占用空间为 [0, 20] 共21个字节
    };
    //3、结构体的整体对齐规则: min(4 max(short, char, int, InnerCustomType)) = 4, 21 不是 4 的整数倍，空间大小变为 24，所以结构体最终占用空间为 24 个字节。
#pragma pack()
    struct CustomType a;
    NSLog(@"%zd", sizeof(a));
}

void pack4llAllTest() {
#pragma pack(4)
    struct CustomType {
        //1、数据成员对齐规则
        char a[2];              // 占用空间大小1 < 4, 偏移量为 1 的倍数, 偏移量为 0,  存放空间位置 [0, 1]
        short b;                // 占用空间大小2 < 4, 偏移量为 2 的倍数, 偏移量为 2,  存放空间位置 [2, 3]
        struct InnerCustomType {
            //1、数据成员对齐规则
            int a1;             // 占用空间大小4 = 4, 偏移量为 4 的倍数, 偏移量为 4,   存放空间位置 [4, 7]
            char b1;            // 占用空间大小1 < 4, 偏移量为 1 的倍数, 偏移量为 8,   存放空间位置 [8]
            long c1;            // 占用空间大小8 > 4, 偏移量为 4 的倍数, 偏移量为 12,  存放空间位置 [12, 19]
            // InnerCustomType 数据成员总共占用空间为 [4, 19] 共16个字节
            //3、结构体的整体对齐规则: min(4, max(long, char, int)) = 4, 16 是 4 的整数倍，空间大小变为 16，所以InnerCustomType结构体最终占用空间为 16 个字节, 范围[4, 19]
        } c;
        int d;                  // 占用空间大小4 = 4, 偏移量为 4 的倍数, 偏移量为 20,  存放空间位置 [20, 23]
        // CustomType结构体数据成员总共占用空间为 [0, 23] 共24个字节
    };
    //3、结构体的整体对齐规则: min(4 max(short, char, int, InnerCustomType)) = 4, 24 是 4 的整数倍，空间大小变为 24，所以结构体最终占用空间为 24 个字节。
#pragma pack()
    struct CustomType a;
    NSLog(@"%zd", sizeof(a));
}

// __attribute__((packed)) 告诉编译器不做任务优化
void packAttribute() {
// 即使设置了#pragma pack(4)，由于结构体中使用了__attribute__((packed)) 属性，依然取消了设置的对齐方式
#pragma pack(4)
    struct CustomType {
        char a;     // 占用1个字节
        short b;    // 占用2字节
        char c;     // 占用1个字节
        int d;      // 占用4个字节
        char e;     // 占用1个字节
    } __attribute__((packed));
    // __attribute__((packed)) 状态下总共占用 9 个字节
#pragma pack()
    struct CustomType a;
    NSLog(@"%zd", sizeof(a));
}

/// 测试xcode 平台的对齐系统
void testXcodePack() {
    // NSOject 的展现形式
    struct NSObject_IMPL {
        Class isa;
    };
    #pragma pack(8)
//    #pragma pack(4)
    // 继承NSOject的TestObject展现形式
    struct TestObject_IMPL {
        struct NSObject_IMPL NSObject_IVARS; // 这里可以直接用 Class isa;替换
        int p1;
        int p2;
        char p3;
    };
    #pragma pack()
    struct TestObject_IMPL s;
    NSLog(@"%zd", sizeof(s));
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
       
//        packAttribute();
//        pack1test();
//        pack2test();
//        pack4test();
//        pack8test();
//        pack4StructTest();
//        pack4llAllTest();
//        packAttribute();
        testXcodePack();
//        struct TestObject_IMPL s;
//        NSLog(@"%zd", sizeof(s));
//        TestObject *obj = [[TestObject alloc] init];
//
//        NSLog(@"%zd", malloc_size((__bridge const void *)(obj)));
//        NSLog(@"%zd", class_getInstanceSize([obj class]));

    }
    return 0;
}


