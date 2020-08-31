//
//  MutableSetSearchPattern.m
//  KVC
//
//  Created by Honey on 2019/4/29.
//  Copyright © 2019 Honey. All rights reserved.
//

#import "MutableSetSearchPattern.h"

@implementation MutableSetSearchPattern
- (instancetype)init
{
    self = [super init];
    if (self) {
        self->internalMutableSet = [@[@1, @2,@3] mutableCopy];
    }
    return self;
}

/*********************************************************************************************************************/
//搜索第一梯队
//这两个方法的优先级较下面同性质的两个方法的优先级要高
//add<Key>Object: and remove<Key>Object:
//- (void)addMutableSetObject:(id)object {
//    [self->internalMutableSet addObject:object];
//}
//- (void)removeOMutableSetObject:(id)object {
//    [self->internalMutableSet removeObject:object];
//}

//add<Key>: and remove<Key>:
//- (void)addMutableSet:(NSMutableSet *)object {
//    [self->internalMutableSet addObjectsFromArray:[NSArray arrayWithArray:object.allObjects]];
//}
//
//- (void)removeMutableSet:(NSMutableSet *)object {
//    [self->internalMutableSet removeObject:object.allObjects.firstObject];
//}

////intersect<Key>: or set<Key>:
//- (void)intersectMutableSet:(NSSet<id> *)otherSet {
//    [self->internalMutableSet intersectSet:otherSet];
//}
//
//- (void)setMutableSet:(NSSet<id> *)otherSet {
//    [self->internalMutableSet setSet:otherSet];
//}

/*********************************************************************************************************************/

////搜索第二梯队 getKey key isKey _getKey _keyv未写全，自已补充
//- (void)setMutableSet:(NSMutableSet *)set {
//    self->internalMutableSet = [NSMutableSet setWithArray:set.allObjects];
//}
//
//- (void)_setMutableSet:(NSMutableSet *)set {
//     self->internalMutableSet = [NSMutableSet setWithArray:set.allObjects];
//}
//
//- (NSMutableSet *)_getMutableSet {
//    return self->internalMutableSet;
//}
@end
