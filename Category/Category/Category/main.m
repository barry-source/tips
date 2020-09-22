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

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        [[Animal new] animalInstanceMethod];
    }
    return 0;
}
