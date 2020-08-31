//
//  MutableOrderedSetSearchPattern.m
//  KVC
//
//  Created by Honey on 2019/4/29.
//  Copyright © 2019 Honey. All rights reserved.
//

#import "MutableOrderedSetSearchPattern.h"

@implementation MutableOrderedSetSearchPattern

- (instancetype)init
{
    self = [super init];
    if (self) {
        self->internalMutableSet = [@[@1, @2,@3] mutableCopy];
    }
    return self;
}

/*********************************************************************************************************************/
////搜索第一梯队
////这两个方法的优先级较下面同性质的两个方法的优先级要高
////-insertObject:in<Key>AtIndex: and -removeObjectFrom<Key>AtIndex:
//- (void)insertObject:(id)anObject inMutableOrderedSetAtIndex:(NSUInteger)index {
//    [self->internalMutableSet insertObject:anObject atIndex:index];
//}
//
//- (void)removeObjectFromMutableOrderedSetAtIndex:(NSUInteger)index {
//    [self->internalMutableSet removeObjectAtIndex:index];
//}
//
////-insert<Key>:atIndexes: and -remove<Key>AtIndexes:
//- (void)insertMutableOrderedSet:(NSArray<id> *)objects atIndexes:(NSIndexSet *)indexes {
//    [self->internalMutableSet insertObjects: objects atIndexes:indexes];
//}
//
//- (void)removeMutableOrderedSetAtIndexes:(NSIndexSet *)indexes {
//    [self->internalMutableSet removeObjectsAtIndexes:indexes];
//}
//
////replaceObjectIn<Key>AtIndex:withObject:
////replace<Key>AtIndexes:with<Key>:,
//- (void)replaceObjectInMutableOrderedSetAtIndex:(NSUInteger)index withObject:(NSArray<id> *)object {
//    [self->internalMutableSet replaceObjectAtIndex:index withObject:object];
//}
//
//- (void)replaceMutableOrderedSetAtIndexes:(NSIndexSet *)indexes withMutableArray:(NSArray<id> *)objects {
//    [self->internalMutableSet replaceObjectsAtIndexes:indexes withObjects:objects];
//}

/*********************************************************************************************************************/

////搜索第二梯队 getKey key isKey _getKey _key未写全，自已补充
//- (void)setMutableArray:(NSArray *)array {
//    self->internalMutableArray = [NSMutableArray arrayWithArray:array];
//}
//
//- (void)_setMutableOrderedSet:(NSMutableOrderedSet *)set {
//    self->internalMutableSet = set;
//}
//
//- (NSMutableOrderedSet *)_getMutableOrderedSet {
//    return self->internalMutableSet;
//}
@end
