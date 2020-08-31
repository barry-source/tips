//
//  SearchPattern.m
//  KVC
//
//  Created by Honey on 2019/4/29.
//  Copyright © 2019 Honey. All rights reserved.
//

#import "SearchPattern.h"

@implementation SearchPattern

- (instancetype)init
{
    self = [super init];
    if (self) {
        _interalArray = @[@1, @2, @3];
        _interalSet = [NSSet setWithArray:@[@5, @2, @3]];
    }
    return self;
}

+ (BOOL)accessInstanceVariablesDirectly {
    return true;
}

/****************************************get搜索*******************************************/
//第一搜索梯队
//- (NSString *)getName {
//    return @"getName";
//}

//- (NSString *)name {
//    return @"name";
//}

//- (NSString *)isName {
//    return @"isName";
//}

//- (NSString *)_getName {
//    return @"_getName";
//}

//- (NSString *)_name {
//    return @"_name";
//}
/*********************************************************************************************************************/
////第二搜索梯队
//- (NSInteger)countOfName {
//    return self->_interalArray.count;
//}
//
////优先级最高
//- (void)getName:(id _Nonnull __unsafe_unretained [_Nonnull])objects range:(NSRange)range {
//    [self->_interalArray getObjects:objects range:range];
//}
//
////优先级其次
//- (id)objectInNameAtIndex: (NSInteger)index {
//    return [self->_interalArray objectAtIndex:index];
//}
//
////优先级最低
//- (NSArray<id> *)NameAtIndexes:(NSIndexSet *)indexes {
//    return [self->_interalArray objectsAtIndexes:indexes];
//}
/*********************************************************************************************************************/
//第三搜索梯队
//- (NSInteger)countOfName {
//    return self->_interalSet.count;
//}
//
//- (NSEnumerator<id> *)enumeratorOfName {
//    return self->_interalSet.objectEnumerator;
//}
//
//- (id)memberOfName:(id)object {
//    if ([self->_interalSet containsObject:object]) {
//        return object;
//    } else {
//        return nil;
//    }
//}

/****************************************set搜索*******************************************/
- (void)setName:(NSString *)name {
    _name = name;
}

- (void)_setName:(NSString *)name {
    _name = name;
}

/************mutablearray**************/
//- (void)addObject:(id)object {
//    [self->mutableArray addObject:object];
//}
//- (void)removeObject:(id)object {
//    [self->mutableArray removeObject:object];
//}

//-insertObject:in<Key>AtIndex: and -removeObjectFrom<Key>AtIndex:
//- (void)insertObject:(id)anObject inTestAtIndex:(NSUInteger)index {
//
//    [self->mutableArray insertObject:anObject atIndex:index];
//}
//
//- (void)removeObjectFromTestAtIndex:(NSUInteger)index {
//    [self->mutableArray removeObjectAtIndex:index];
//}
//
////-insert<Key>:atIndexes: and -remove<Key>AtIndexes:
//- (void)insertTest:(NSArray<id> *)objects atIndexes:(NSIndexSet *)indexes {
//    [self->mutableArray insertObjects: objects atIndexes:indexes];
//}
//
//- (void)removeTestAtIndexes:(NSIndexSet *)indexes {
//    [self->mutableArray removeObjectsAtIndexes:indexes];
//}

//- (void)setTest:(NSMutableArray*)array {
//    self->mutableArray = array;
//}
//
//- getTest {
//    return self->mutableArray;
//}

//- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
//
//}
//
//- (id)valueForUndefinedKey:(NSString *)key {
//    return nil;
//}

/****mutableset*/
// add<Key>Object: and remove<Key>Object:
//- (void)addTestObject:(id)object {
//    [self->mutableSet addObject:object];
//}
//- (void)removeTestObject:(id)object {
//    [self->mutableSet removeObject:object];
//}

//add<Key>:, and remove<Key>:
//- (void)addTest:(id)object {
//    [self->mutableSet unionSet:object];
//}
//
//- (void)removeTest:(id)object {
//    [self->mutableSet minusSet:object];
//}


/************/
/************mutablearray**************/

// add<Key>Object: and remove<Key>Object:
//- (void)addTestObject:(id)object {
//    [self->mutableOrderedSet addObject:object];
//}
//- (void)removeTestObject:(id)object {
//    [self->mutableOrderedSet removeObject:object];
//}
//
//// insertObject:in<Key>AtIndex: and removeObjectFrom<Key>AtIndex:
//- (void)insertObject:(id)anObject inTestAtIndex:(NSUInteger)index {
//    [self->mutableOrderedSet insertObject:anObject atIndex:index];
//}
//
//- (void)removeObjectFromTestAtIndex:(NSUInteger)index {
//    [self->mutableOrderedSet removeObjectAtIndex:index];
//}
//
////insert<Key>:atIndexes: and remove<Key>AtIndexes:
//- (void)insertTest:(NSArray<id> *)objects atIndexes:(NSIndexSet *)indexes {
//    [self->mutableOrderedSet insertObjects: objects atIndexes:indexes];
//}
//
//- (void)removeTestAtIndexes:(NSIndexSet *)indexes {
//    [self->mutableOrderedSet removeObjectsAtIndexes:indexes];
//}

@end
