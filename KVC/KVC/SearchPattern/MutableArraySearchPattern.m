//
//  MutableArraySearchPattern.m
//  KVC
//
//  Created by Honey on 2019/4/29.
//  Copyright © 2019 Honey. All rights reserved.
//

#import "MutableArraySearchPattern.h"

@implementation MutableArraySearchPattern

- (instancetype)init
{
    self = [super init];
    if (self) {
        self->internalMutableArray = [@[@1, @2,@3] mutableCopy];
    }
    return self;
}

/*********************************************************************************************************************/
////搜索第一梯队
////这两个方法的优先级较下面同性质的两个方法的优先级要高
////-insertObject:in<Key>AtIndex: and -removeObjectFrom<Key>AtIndex:
//- (void)insertObject:(id)anObject inMutableArrayAtIndex:(NSUInteger)index {
//    [self->internalMutableArray insertObject:anObject atIndex:index];
//}
//
//- (void)removeObjectFromMutableArrayAtIndex:(NSUInteger)index {
//    [self->internalMutableArray removeObjectAtIndex:index];
//}
//
////-insert<Key>:atIndexes: and -remove<Key>AtIndexes:
//- (void)insertMutableArray:(NSArray<id> *)objects atIndexes:(NSIndexSet *)indexes {
//    [self->internalMutableArray insertObjects: objects atIndexes:indexes];
//}
//
//- (void)removeMutableArrayAtIndexes:(NSIndexSet *)indexes {
//    [self->internalMutableArray removeObjectsAtIndexes:indexes];
//}
//
////replaceObjectIn<Key>AtIndex:withObject:
////replace<Key>AtIndexes:with<Key>:,
//- (void)replaceObjectInMutableArrayAtIndex:(NSUInteger)index withObject:(NSArray<id> *)object {
//    [self->internalMutableArray replaceObjectAtIndex:index withObject:object];
//}
//
//- (void)replaceMutableArrayAtIndexes:(NSIndexSet *)indexes withMutableArray:(NSArray<id> *)objects {
//    [self->internalMutableArray replaceObjectsAtIndexes:indexes withObjects:objects];
//}

/*********************************************************************************************************************/

////搜索第二梯队 getKey key isKey _getKey _key  未写全，自已补充
//- (void)setMutableArray:(NSArray *)array {
//    self->internalMutableArray = [NSMutableArray arrayWithArray:array];
//}

- (void)_setMutableArray:(NSArray *)array {
    self->internalMutableArray = [NSMutableArray arrayWithArray:array];
}

- (NSMutableArray *)_getMutableArray {
    return self->internalMutableArray;
}

@end
