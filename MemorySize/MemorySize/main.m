//
//  main.m
//  MemorySize
//
//  Created by tongshichao on 2020/8/14.
//  Copyright © 2020 tongshichao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <malloc/malloc.h>


// 对齐原则：
// 1、数据成员对齐规则：结构体的数据成员，首个数据成员放在偏移量为0的地方，后序的数据成员偏移量为 #pragma pack(n) 指定的数据 n 和当前的数据成员占用的字节大小的最小值的整数倍，少则补齐.
// 2、结构体中包含结构体，该结构体成“自身数据”类型占用的大小为结构体中成员类型占用最大字节数。
// 3、结构体的整体对齐规则：结构体在按照规则1对齐之后,结构体本身也要对齐。最终大小为 #pragma pack(n) 指定的数据 n 和结构体中成员占用的最大字节数中最小值的整数倍，少则补齐.
int main(int argc, const char * argv[]) {
    @autoreleasepool {
       
        
        
#pragma pack(1)
        struct AA {
            int a;   //长度4 > 1 按1对齐；偏移量为0；存放位置区间[0,3]
            char b;  //长度1 = 1 按1对齐；偏移量为4；存放位置区间[4]
            short c; //长度2 > 1 按1对齐；偏移量为5；存放位置区间[5,6]
            char d;  //长度1 = 1 按1对齐；偏移量为6；存放位置区间[7]
            //整体存放在[0~7]位置区间中，共八个字节。
        };
#pragma pack()
        struct AA a;
        NSLog(@"%zd", sizeof(a));

//        #pragma pack(8)
//
//        struct s {
//
//        } __attribute__((packed));
//        #pragma pack()
    }
    return 0;
}
