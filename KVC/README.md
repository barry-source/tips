# KVC

[KVC](https://www.jianshu.com/p/649ed93025ae)

> iOS在实际开发过程中用`KVC`的地方也是不少的，但是很少有时间探究里面涵盖的内容，网上的一些文章也纯属是翻译的官方文档。有些细节根本没有验证完全, 本文着重探索一下里面的实现细节。

![KVC.png](https://upload-images.jianshu.io/upload_images/1846524-51031bd12a0afb03.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/650)
## 一、KVC 定义
&#160;&#160;&#160;&#160;&#160;&#160;&#160;`KVC`全称`Key Value Coding`，具体来说就是`KVC`是由`NSKeyValueCoding`非正式协议启用的机制，对象采用该机制提供对其属性的间接访问。当对象符合键值编码时(通常在OC中，继承`NSObject`即可)，其属性可通过字符串参数通过简洁，统一的消息传递接口来存取消息。它属于间接访问对象的属性，区别于属性的直接访问方法`setter`和`getter`，亦或直接访问成员变量.因为是间接访问属性，所以`KVC`性能比不上直接存取属性的方法，但是可以提高程序的灵活性。必要的时候可以减少冗余代码。相关参考[KVC官方文档](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/KeyValueCoding/BasicPrinciples.html#//apple_ref/doc/uid/20002170-BAJEAIEE)

## 二、NSKeyValueCoding
![图片.png](https://upload-images.jianshu.io/upload_images/1846524-3e957ef0119543c8.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/650)

## 三、基本操作
`KVC`对属性的操作主要分为：
`基础属性`--标量(整型，浮点型等)，字符串，布尔类型，NSNumber, NSColor等
`一对一关系的属性`--当前对象有一个对象属性，对象属性在改变自己内部属性的时候，对象属性不会改变
`一对多关系的属性`--通过NSArray或NSSet包含的其它对象集合
### 3.1 基础属性
```Objective-C
//银行账户
@interface BankAccount : NSObject

@property (nonatomic) NSNumber* currentBalance;              // An attribute 
@property (nonatomic) Person* owner;                         // A to-one relation
@property (nonatomic) NSArray< Transaction* >* transactions; // A to-many relation

@end
```
使用属性字符串作`key`，来查找当前的属性
```Objective-C
//存取普通属性 An attribute
NSLog(@"currentBalance--%@", [self.account valueForKey:@"currentBalance"]);//通过key获取属性
[self.account setValue:@(111) forKey:@"currentBalance"];                   //通过key设置属性值
NSLog(@"currentBalance--%@", [self.account valueForKey:@"currentBalance"]);//通过key获取属性
```
### 3.2 一对一关系的属性和Key Paths
```Objective-C
// 个人信息
NS_ASSUME_NONNULL_BEGIN

@interface Person : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *address;

@end
```
可以通过`key path` 获取`BankAccount`对象中的属性`person`,进而获取`Person`的`name`属性

```Objective-C
//一对一属性 to - one
NSLog(@"name--%@", [self.account valueForKeyPath:@"owner.name"]); //通过keypath获取属性
[self.account setValue:@"NewName" forKeyPath:@"owner.name"];      //通过keypath设置属性值
NSLog(@"name--%@", [self.account valueForKeyPath:@"owner.name"]); //通过keypath获取属性
```
&#160;&#160;&#160;&#160;&#160;&#160;&#160;所谓`Key Paths` 是指由一串点分隔键组成的字符串，用于指定要遍历的对象属性序列。字符串序列中的第一个键的属性是相对于接收者的(owner是 self.account的属性，接收者是self.account),子序列中的第一个键的属性是相对于前一个属性的(name是owner的属性)

### 3.3 一对多关系的属性
&#160;&#160;&#160;&#160;&#160;&#160;&#160;当给键值编码兼容对象发送`valueForKeyPath：`消息时，可以在键路径中嵌入一个集合运算符。 集合运算符是一个小符号列表之一，前面是一个符号（@），它指定了getter在返回之前应该以某种方式操作数据的操作。 NSObject提供的`valueForKeyPath：`的默认实现实现了这种行为。其格式如下：

![keypath.jpg](https://upload-images.jianshu.io/upload_images/1846524-a9b9ccefd5e6356f.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
- `@collectionOperator`左侧是`Left key path`,可以省略(如果当属性对象是NSarray时)
- `@collectionOperator`左侧是`Right key path`，除了`@count`集合操作符，其它的`Right key path`必须存在
#### 3.3.1 Aggregation Operators聚合操作符
&#160;&#160;&#160;&#160;&#160;&#160;&#160;聚合运算符以某种方式合并集合的对象，并返回通常与右键路径中指定的属性的数据类型匹配的单个对象。 @count运算符是一个例外 - 它没有正确的键路径，总是返回一个NSNumber实例。

- **@avg**
```Objective-C
NSNumber *transactionAverage = [self.account.transactions valueForKeyPath:@"@avg.amount"];
```
- **@count**
```Objective-C
NSNumber *numberOfTransactions = [self.account.transactions valueForKeyPath:@"@count"];
```
- **@max**
```Objective-C
NSDate *latestDate = [self.account.transactions valueForKeyPath:@"@max.date"];
```
- **@min**
```Objective-C
NSDate *earliestDate = [self.account.transactions valueForKeyPath:@"@min.date"];
```
- **@sum**
```Objective-C
NSNumber *amountSum = [self.account.transactions valueForKeyPath:@"@sum.amount"];
```
#### 3.3.2 Array Operators数组操作符
数组操作符通过调用`valueForKeyPath`和right key path 指示的对象返回一个特定的序列
- **@distinctUnionOfObjects** 返回一个不重复元素的Array
```Objective-C
NSArray *distinctPayees = [self.account.transactions valueForKeyPath:@"@distinctUnionOfObjects.payee"];
```
- **@unionOfObjects** 返回一个所有元素的Array
```Objective-C
NSArray *distinctPayees = [self.account.transactions valueForKeyPath:@"@distinctUnionOfObjects.payee"];
```
#### 3.3.3 Nesting Operators嵌套操作符
嵌套操作作用在一个嵌套的序列上，序列中的每一个元素也是一个序列。
- **@distinctUnionOfArrays** 返回一个不重复元素的Array
```Objective-C
NSArray *collectedDistinctPayees = [arrayOfArrays valueForKeyPath:@"@distinctUnionOfArrays.payee"];
```
- **@unionOfArrays** 返回一个所有元素的Array
```Objective-C
NSArray *collectedPayees = [arrayOfArrays valueForKeyPath:@"@unionOfArrays.payee"];
```
- **@distinctUnionOfSets** 返回一个不重复元素的Set
```Objective-C
NSSet *set1 = [NSSet setWithArray:self.account.transactions];
NSSet *set2 = [NSSet setWithArray:moreTransactions];
NSSet *set = [NSSet setWithObjects:set1, set2, nil];
NSSet *collectedSetPayees = [set valueForKeyPath:@"@distinctUnionOfSets.payee"];
```

###### 下面是基本的存取方法的简介：
- `valueForKey:`根据给定的`key`获取当前对象对应属性的`value`
- `valueForKeyPath:`根据给定的`keyPath`获取当前对象路径上对应属性的`value`，如果路径中有一个`key`不匹配的话，就会调用 `valueForUndefinedKey:`
- `dictionaryWithValuesForKeys:`将当前对象所有的属性和其值，封装成一个字典返回，内部调用`valueForKey:`
- `setValue:forKey:`根据给定的`key`设置当前对象对应属性的`value`
- ` setValue:forUndefinedKey:`如果指定的`key`在当前对象的属性中无法匹配的话，就会调用
- `setValue:forKeyPath:`根据给定的`keyPath`设置当前对象路径上对应属性的`value`，如果路径中有一个`key`不匹配的话，就会调用` setValue:forUndefinedKey`
- `setValuesForKeysWithDictionary:`利用字典设置当前对象的属性值,字典中的每个`key`，对应当前对象中的一个属性，内部实现是多次调用`setValue:forKey`
- `mutableArrayValueForKey:` and `mutableArrayValueForKeyPath:`返回一个可变的数组对象进行操作(像NSMutableArray)
- `mutableSetValueForKey:` and `mutableSetValueForKeyPath:`返回一个可变的Set对象进行操作(像NSMutableSet)
- `mutableOrderedSetValueForKey:` and `mutableOrderedSetValueForKeyPath:`返回一个可变的有序的Set对象进行操作(像NSMutableOrderedSet)

注： 非对象属性通过KVC设置值，如果值nil，会调用`setNilValueForKey:`,其内部触发一个异常，可以根据需要重写它来进行其它操作
## 四、非对象类型的表示
KVC支持scalar和结构体，对于KVC中的value,必须是一个对象类型，所以scalar和结构体必须包裹成相应的对象。
- **scalar类型可以使用NSNumber或者简写@()**
```Objective-C
[self.account setValue:[NSNumber numberWithInt:10] forKey:@"no"];
[self.account setValue:@(10) forKey:@"no"];
```
- **结构体可以使用NSValue包裹**
```Objective-C
typedef struct {
    float x, y, z;
} ThreeFloats;

NS_ASSUME_NONNULL_BEGIN

@interface StructValueTest : NSObject

@property (nonatomic) ThreeFloats threeFloats;

@end

```
```Objective-C
    StructValueTest *myClass = [[StructValueTest alloc] init];
    NSValue *result = [myClass valueForKey:@"threeFloats"]; 
    ThreeFloats temp;
    [result getValue:&temp];   //通过getValue获取真实的类型
    NSLog(@"修改前x-%f,y-%f,z-%f", temp.x, temp.y, temp.z);

    ThreeFloats floats = {1., 2., 3.};
    NSValue* value = [NSValue valueWithBytes:&floats objCType:@encode(ThreeFloats)];
    [myClass setValue:value forKey:@"threeFloats"]; //设置新值
    result = [myClass valueForKey:@"threeFloats"]; 
    [result getValue:&temp];   //通过getValue获取真实的类型
    NSLog(@"修改前x-%f,y-%f,z-%f", temp.x, temp.y, temp.z);
```

## 五、属性的验证
Key-value coding protocol支持属性验证，但是不会自动地调用验证方法(如果自动调用肯定会消耗性能)，必须根据自己的需求在合适的时机调用 `validateValue:forKey:error:`。但是默认的方法始终返回Yes,所以无法验证，必须写一个`validate<Key>:error:`方法也实现具体的验证思路。

- **如果不写`validate<Key>:error:`方法，下面的验证无效**
```Objective-C
Person* person = [[Person alloc] init];
NSError* error;
NSString* name = @"John";
if (![person validateValue:&name forKey:@"name" error:&error]) {
NSLog(@"%@",error);
}
```
- **验证`validateName:error:`**
```Objective-C
- (BOOL)validateName:(id *)ioValue error:(NSError **)outError {
    //这里只判断类型是不是NSString类型，是返回true，否返回false
    NSString *result = (NSString *)*ioValue;
    if ([result isKindOfClass:[NSString class]]) {
        return true;
    }
    NSError *error = [[NSError alloc] initWithDomain:@"0" code:100 userInfo:@{@"info":@"type error"}];
    *outError = error;
    return false;
}
```
```Objective-C
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
```
验证结果：
`2019-04-29 01:41:08.969260+0800 KVC[6294:243510] Error Domain=0 Code=100 "(null)" UserInfo={info=type error}`

## 六、基本Getter方法的搜索模式
NSObject提供的NSKeyValueCoding协议的默认实现使用明确定义的一套规则将基于`Key`的访问器的调用映射到对象的内部属性。也就是说内部有自己的一套访问存取方法，实例变量和其它的一些相关方法。
这是valueForKey:的默认实现，给定一个key当做输入参数，开始下面的步骤，在这个接收valueForKey:方法调用的类内部进行操作。

- 1通过getter方法搜索实例，搜索顺序为`get<Key>`, `<key>`, `is<Key>`, `_get<Key>`,`_<key>`方法
- 2如果相应的存取方法没找到，那么查找下面四个方法`countOf<Key>`,` get<Key>:range:`,`objectIn<Key>AtIndex:`, `<key>AtIndexes:`，第一个方法实现的情况下，剩下的三个方法实现其一就行，上面三个方法的顺序就是他们的调用优先级,此过程是响应NSArray对应的方法(看样子只是对`NSArray`类型有实际作用)，如果上面相应的方法没有实现进入步骤3
- 3 查找`countOf<Key>`, `enumeratorOf<Key>`, `and memberOf<Key>:`方法,此过程是响应NSSet对应的方法(看样子只是对`NSSet`类型有实际作用)，如果没有找到进入步骤4
- 4如果第3步还是没有找到，且`accessInstanceVariablesDirectly`是返回YES的。
- 5根据顺序搜索一个名为`_<key>`、`_is<Key>`、`<key>`、`is<Key>`的实例变量，然后返回。
如果取回的是一个对象指针，则直接返回这个结果。
如果取回的是一个基础数据类型，但是这个基础数据类型是被`NSNumber`支持的，则存储为`NSNumber`并返回。
如果取回的是一个不支持`NSNumber`的基础数据类型，则通过`NSValue`进行存储并返回。
- 6如果所有情况都失败，则调用`valueForUndefinedKey:`方法并抛出异常，这是默认行为。但是子类可以重写此方法,处理异常或什么也不操作

**搜索路径如下图：**
![搜索路径.png](https://upload-images.jianshu.io/upload_images/1846524-ba6990d6dc9909ee.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

## 七、基本Setter搜索模式
这是`setValue:forKey:`的默认实现，根据给定的`key`设置相应的`value`

- 查找`set<Key>:`或`_set<Key>`命名的setter，按照这个顺序，如果找到的话，调用这个方法并将值传进去(根据需要进行对象转换)。
- 如果没有发现一个简单的setter，但是`accessInstanceVariablesDirectly`类属性返回`YES`，则查找一个命名规则为`_<key>`、`_is<Key>`、`<key>`、`is<Key>`的实例变量。根据这个顺序，如果发现则将value赋值给实例变量。
如果没有发现setter或实例变量，则调用`setValue:forUndefinedKey:`方法，并默认抛出一个异常，子类可以重写，指定自己的行为
**搜索路径如下图：**
![图片.png](https://upload-images.jianshu.io/upload_images/1846524-b5a1f1925081b096.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
## 八、可变数组搜索模式
`mutableArrayValueForKey:`根据给定的`key`返回一个可变的`value`（可变数组）
**`mutableArrayValueForKey:`内部调用顺序如下：**

- 1实现可变数组方法`insertObject:in<Key>AtIndex:`和`removeObjectFrom<Key>AtIndex:` (对应NSMutableArray中的`insertObject:atIndex: `and `removeObjectAtIndex:)`这对操作与`insert<Key>:atIndexes: `和`remove<Key>AtIndexes:`（对应`NSMutableArray`中的`insertObjects:atIndexes`和`removeObjectsAtIndexes:`）这对操作从中选一个`insert`操作和一个`remove`操作即可。
如果还实现了操作`replaceObjectIn<Key>AtIndex:withObject:`或`replace<Key>AtIndexes:with<Key>:,`代理对象会在适当的情况下使用它们，以获得最佳性能
- 2如果没有实现可变数组方法，那么会找相应的存取器方法`set<Key>:`方法和`<key>`方法（这个点和官方文档不太一致，实测只有同时实现setter方法和getter方法才会正常运行，否则崩溃）.set方法的搜索按`set<Key>:`，`_set<Key>`这个顺序，get方法的搜索按`get<Key>`, `<key>`, `is<Key>`, `_get<Key>`,`_<key>`这个顺序
- 3如果第2步还是没有找到，且`accessInstanceVariablesDirectly`是返回YES的。执行第4步
- 4按顺序搜索一个名为`_<key>`、`_is<Key>`、`<key>`、`is<Key>`的实例变量，然后返回。
- 5如果所有情况都失败，则调用`valueForUndefinedKey:`方法并抛出异常，这是默认行为。但是子类可以重写此方法,处理异常或什么也不操作

**搜索路径如下图：**
![图片.png](https://upload-images.jianshu.io/upload_images/1846524-eb495c2393646af6.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
## 九、可变有序Set搜索模式
`mutableOrderedSetValueForKey:`根据给定的`key`返回一个可变的`value`（有序可变Set）
其实现流程和可变数组大致一致，不再赘述，可看[demo](https://github.com/tsc000/KVC)
## 十、可变Set搜索模式
`mutableSetValueForKey:`,根据给定的`key`返回一个可变的`value`（可变Set）
其实现流程和可变数组大致一致，这里只给一个流程图，具体可查看demo

![图片.png](https://upload-images.jianshu.io/upload_images/1846524-375dff5368509b84.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

## 十一、KVC其它操作

- Key Paths
OC中的`key paths` 必须是一个字符串，字样就会造成一定的写错机率，
可以借助`runtime`的一些方法`[object valueForKey:NSStringFromSelector(@selector(method))]`;但是这样势必造成一定的性能损失，怎么取舍看自己的情况。
对于swift 4中新增了`keypath`的操作，它要比OC中一keypath更加灵活。不再使用字符串，这样就可以防止写错的情况。

```Objective-C
class User: NSObject{
    var name:String = ""  
    var age:Int = 0 
}
let user = User()
user.name = "hangge"
user.age = 100
//取值
let name = user1[keyPath: \User.name]
print(name)
//设置值
user1[keyPath: \User.name] = "hangge.com"
```
- 修改私有属性的值
OC语言中没有绝对的私有，我们可以通过runtime获取相应的私有属性，然后可根据需要修改，比如：
KVC可以给对象的私有变量赋值(UIPageControl)
- 字典转模型
`setValuesForKeysWithDictionary:`
