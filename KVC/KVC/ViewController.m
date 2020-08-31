//
//  ViewController.m
//  KVC
//
//  Created by Honey on 2019/4/28.
//  Copyright © 2019 Honey. All rights reserved.
//

#import "ViewController.h"
#import "Person.h"
#import "BankAccount.h"
#import "Transaction.h"
#import "StructValueTest.h"
#import "SearchPattern.h"
#import "MutableArraySearchPattern.h"
#import "MutableOrderedSetSearchPattern.h"
#import "MutableSetSearchPattern.h"

@interface ViewController ()
@property (nonatomic, strong) BankAccount *account;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

//    [self displayBasicOperator];
//    [self nestedOperator];
//    [self nonObjectType];
//    [self validateProperty];
//    [self searchPattern];
//    [self mutableArraySearchPattern];
//    [self mutableOrderedSetSearchPattern];
    [self mutableSetSearchPath];
}

//可变set
- (void)mutableSetSearchPath {
//    // 搜索第一梯队测试 (可变有序Set方法)
//    MutableSetSearchPattern *search = [[MutableSetSearchPattern alloc] init];
//    NSMutableSet *set = [search mutableSetValueForKey:@"mutableSet"];
//    [set addObject:@5];
//    [set addObject:@4];
//    [set removeObject:@5];
//    NSLog(@"%@", set);
//    NSLog(@"%@", search->internalMutableSet);
//
//    // 搜索第二梯队测试（存取器方法，setter getter）
//    MutableSetSearchPattern *search = [[MutableSetSearchPattern alloc] init];
//    NSMutableSet *set = [search mutableSetValueForKey:@"mutableSet"];
//    [set addObject:@5];
//    NSLog(@"%@", set);
//    NSLog(@"%@", search->internalMutableSet);

     // 搜索第三梯队测试（查找成员变量）
    MutableSetSearchPattern *search = [[MutableSetSearchPattern alloc] init];
    NSMutableSet *set = [search mutableSetValueForKey:@"mutableSet"];
    [set addObject:@5];
    NSLog(@"%@", set);
    NSLog(@"_mutabledSet--%@", search->_mutableSet);
    NSLog(@"_isMutableSet--%@", search->_isMutableSet);
    NSLog(@"mutableSet--%@", search->mutableSet);
    NSLog(@"isMutableSet--%@", search->isMutableSet);
}

//有序可变set
- (void)mutableOrderedSetSearchPattern {
//    // 搜索第一梯队测试 (可变有序Set方法)
//    MutableOrderedSetSearchPattern *search = [[MutableOrderedSetSearchPattern alloc] init];
//    NSMutableOrderedSet *set = [search mutableOrderedSetValueForKey:@"mutableOrderedSet"];
//    [set insertObject:@4 atIndex:0];
//    [set insertObject:@5 atIndex:0];
//    [set removeObjectAtIndex:0];
//    NSLog(@"%@", set);
//    NSLog(@"%@", search->internalMutableSet);

//    // 搜索第二梯队测试（存取器方法，setter getter）
//    MutableOrderedSetSearchPattern *search = [[MutableOrderedSetSearchPattern alloc] init];
//    NSMutableOrderedSet *set = [search mutableOrderedSetValueForKey:@"mutableOrderedSet"];
//    [set insertObject:@4 atIndex:0];
//    NSLog(@"%@", set);
//    NSLog(@"%@", search->internalMutableSet);

    // 搜索第三梯队测试（查找成员变量）
    MutableOrderedSetSearchPattern *search = [[MutableOrderedSetSearchPattern alloc] init];
    NSMutableOrderedSet *set = [search mutableOrderedSetValueForKey:@"mutableOrderedSet"];
    [set insertObject:@4 atIndex:0];
    NSLog(@"%@", set);
    NSLog(@"_mutableOrderedSet--%@", search->_mutableOrderedSet);
    NSLog(@"_isMutableOrderedSet--%@", search->_isMutableOrderedSet);
    NSLog(@"mutableOrderedSet--%@", search->mutableOrderedSet);
    NSLog(@"isMutableOrderedSet--%@", search->isMutableOrderedSet);
}

//mutableArrayValueForKey:
- (void)mutableArraySearchPattern {

    // 搜索第一梯队测试 (可变数组方法)
//    MutableArraySearchPattern *search = [[MutableArraySearchPattern alloc] init];
//    NSMutableArray *array = [search mutableArrayValueForKey:@"mutableArray"];
//    [array insertObject:@4 atIndex:0];
//    [array insertObject:@5 atIndex:0];
//    [array removeObjectAtIndex:0];
//    NSLog(@"%@", array);
//    NSLog(@"%@", search->internalMutableArray);

//    // 搜索第二梯队测试（存取器方法，setter getter）
//    MutableArraySearchPattern *search = [[MutableArraySearchPattern alloc] init];
//    NSMutableArray *array = [search mutableArrayValueForKey:@"mutableArray"];
//    [array insertObject:@4 atIndex:0];
////    [array removeObjectAtIndex:0];
//    NSLog(@"%@", array);
//    NSLog(@"%@", search->internalMutableArray);

    // 搜索第三梯队测试（查找成员变量）
    MutableArraySearchPattern *search = [[MutableArraySearchPattern alloc] init];
    NSMutableArray *array = [search mutableArrayValueForKey:@"mutableArray"];
    [array insertObject:@4 atIndex:0];
    //    [array removeObjectAtIndex:0];
    NSLog(@"%@", array);
    NSLog(@"%@", search->internalMutableArray);

    NSLog(@"_mutableArray--%@", search->_mutableArray);
    NSLog(@"_isMutableArray--%@", search->_isMutableArray);
    NSLog(@"mutableArray--%@", search->mutableArray);
    NSLog(@"isMutableArray--%@", search->isMutableArray);
}

//搜索步骤验证
- (void)searchPattern {
    SearchPattern *search = [[SearchPattern alloc] init];
//    search->_name = @"_name";
//    search->_isName = @"_isName";
//    search->name = @"name";
//    search->isName = @"isName";
    NSLog(@"%@", [search valueForKey:@"name"]);

    [search setValue:@"newname" forKey:@"name"];
    NSLog(@"%@", [search valueForKey:@"name"]);

//    [search setValue:@"modifyname" forKey:@"name"];
//    NSLog(@"%@", search->_name);
//    //    NSArray *array = [NSArray arrayWithContentsOfURL:[NSURL fileURLWithPath:bundlePath]];
//
//    //     let bundle = Bundle.main.path(forResource: "weatherJSON", ofType: nil)
//
//    self.person = [[Person alloc] init];
//    //    self.person->_name = @"tese";
//    self.person->array = @[@1, @2];
//    self.person->mutableArray = [NSMutableArray arrayWithObjects:@(1), @(3), nil];
//    self.person->mutableSet = [NSMutableSet setWithObjects:@(1), @(3), @5, nil];
//    self.person->mutableOrderedSet = [NSMutableOrderedSet orderedSetWithObjects:@(1), @(3), @5, @6, nil];
//    //     self.person->_isTest = [NSMutableArray arrayWithObjects:@(1), @(3), nil];
//    //    [self.person setValue:@"modify" forKey:@"name"];
//    //    [self.person setValue:@[@3, @2] forKey:@"array"];
//    //    [self.person mutableSetValueForKey:@"testMutableArray"];
//    //    NSLog(@"%@", [self.person valueForKey:@"name"]);
//    //    NSLog(@"%@", [self.person valueForKey:@"testArray"]);
//    //    NSMutableArray *array = [self.person mutableArrayValueForKey:@"test"];
//    //    [array insertObject:@4 atIndex:0];
//    //    NSLog(@"%@", self.person->_isTest);
//
//    //    NSMutableSet *set = [self.person mutableSetValueForKey:@"test"];
//    //    [set addObject:@2];
//    //    NSLog(@"%@", self.person->mutableSet);
//
//    NSMutableOrderedSet *set = [self.person mutableOrderedSetValueForKey:@"test"];
//    [set insertObject:@9 atIndex:0];
//    //    [set addObject:@8];
//    NSLog(@"%@", self.person->mutableOrderedSet);
}

//属性验证
- (void)validateProperty {
    Person* person = [[Person alloc] init];
    NSError* error;
//    NSString* name = @"John";
    NSNumber *num = [NSNumber numberWithInt:12];
    if (![person validateValue:&num forKey:@"name" error:&error]) {
        NSLog(@"%@",error);
    }
}

//非对象类型kvc
- (void)nonObjectType {
    [self configureBasicData];
    NSLog(@"no--%@", [self.account valueForKey:@"no"]);
    [self.account setValue:[NSNumber numberWithInt:10] forKey:@"no"];
    [self.account setValue:@(10) forKey:@"no"];
    NSLog(@"no--%@", [self.account valueForKey:@"no"]);

    /************结构体*************/
    StructValueTest *myClass = [[StructValueTest alloc] init];
    NSValue *result = [myClass valueForKey:@"threeFloats"];
    ThreeFloats temp;
    [result getValue:&temp];   //通过getValue获取真实的类型
    NSLog(@"修改前x-%f,y-%f,z-%f", temp.x, temp.y, temp.z);

    ThreeFloats floats = {1., 2., 3.};
    NSValue* value = [NSValue valueWithBytes:&floats objCType:@encode(ThreeFloats)];
    [myClass setValue:value forKey:@"threeFloats"];
    result = [myClass valueForKey:@"threeFloats"];
    [result getValue:&temp];   //通过getValue获取真实的类型
    NSLog(@"修改前x-%f,y-%f,z-%f", temp.x, temp.y, temp.z);
}

//数组操作符演示
- (void)nestedOperator {
    [self configureBasicData];
    NSString *bundlePath = [NSBundle.mainBundle pathForResource:@"content1" ofType:@"json"];
    NSData *data = [[NSData alloc] initWithContentsOfFile:bundlePath];
    NSArray *array = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    if (array == nil) return ;
    NSMutableArray *moreTransactions = [NSMutableArray array];
    for (NSDictionary *dict in array) {
        Transaction *trans = [[Transaction alloc] init];
        [trans setValuesForKeysWithDictionary:dict];
        [moreTransactions addObject:trans];
    }
    NSArray* arrayOfArrays = @[self.account.transactions, moreTransactions];
    NSArray *collectedDistinctPayees = [arrayOfArrays valueForKeyPath:@"@distinctUnionOfArrays.payee"];
    NSArray *collectedPayees = [arrayOfArrays valueForKeyPath:@"@unionOfArrays.payee"];
    NSLog(@"@distinctUnionOfArrays.payee--%@", collectedDistinctPayees);
    NSLog(@"@unionOfArrays.payee--%@", collectedPayees);

    NSSet *set1 = [NSSet setWithArray:self.account.transactions];
    NSSet *set2 = [NSSet setWithArray:moreTransactions];
    NSSet *set = [NSSet setWithObjects:set1, set2, nil];
    NSSet *collectedSetPayees = [set valueForKeyPath:@"@distinctUnionOfSets.payee"];
    NSLog(@"@distinctUnionOfSets.payee--%@", collectedSetPayees);
}

//展示基本的操作
- (void)displayBasicOperator {
    [self configureBasicData];

    //存取普通属性 An attribute
    NSLog(@"currentBalance--%@", [self.account valueForKey:@"currentBalance"]); //通过key获取属性
    [self.account setValue:@(111) forKey:@"currentBalance"];                    //通过key设置属性值
    NSLog(@"currentBalance--%@", [self.account valueForKey:@"currentBalance"]); //通过key获取属性

    //一对一属性 to - one
    NSLog(@"name--%@", [self.account valueForKeyPath:@"owner.name"]); //通过keypath获取属性
    [self.account setValue:@"NewName" forKeyPath:@"owner.name"];      //通过keypath设置属性值
    NSLog(@"name--%@", [self.account valueForKeyPath:@"owner.name"]); //通过keypath获取属性

//    [self.account setValue:nil forKey:@"test"];
//    NSLog(@"%d", self.account.test);

    NSNumber *transactionAverage = [self.account.transactions valueForKeyPath:@"@avg.amount"];
    NSLog(@"@avg.amount-%@", transactionAverage);
    NSDate *earliestDate = [self.account.transactions valueForKeyPath:@"@min.date"];
    NSLog(@"@min.date-%@", earliestDate);
    NSNumber *amountSum = [self.account.transactions valueForKeyPath:@"@sum.amount"];
    NSArray *distinctPayees = [self.account.transactions valueForKeyPath:@"@distinctUnionOfObjects.payee"];
    NSLog(@"@sum.amount--%@", amountSum);
    NSLog(@"@distinctUnionOfObjects.payee--%@", distinctPayees);
}

//配置基础数据
- (void)configureBasicData {
    NSString *bundlePath = [NSBundle.mainBundle pathForResource:@"content" ofType:@"json"];
    NSData *data = [[NSData alloc] initWithContentsOfFile:bundlePath];
    NSArray *array = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    if (array == nil) return ;

    Person *person = [[Person alloc] init];
    person.name = @"OldName";

    NSMutableArray *transactions = [NSMutableArray array];
    for (NSDictionary *dict in array) {
        Transaction *trans = [[Transaction alloc] init];
        [trans setValuesForKeysWithDictionary:dict];
        [transactions addObject:trans];
    }

    self.account = [[BankAccount alloc] init];
    self.account.currentBalance = [NSNumber numberWithInt:1000];
    self.account.owner = person;
    self.account.transactions = transactions;
}

@end
