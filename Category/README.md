### 面试题

> Category的实现原理，Category能不能加属性。如果不能，为什么？

> Category中有load方法吗？load方法的调用时机？load 方法能继承吗？

> load、initialize在category中的调用的顺序，以及出现继承时他们之间的调用的过程

> load、initialize的区别，以及它们在category重写的时候的调用的次序。

下面先来段测试代码

```Objective-C

/// Animal.h
@interface Animal : NSObject

- (void)run;

@end

/// Animal.m

@implementation Animal

- (void)run {
    NSLog(@"Animal --- run");
}

@end

///  Animal+Function1.h

@interface Animal (Function1) <NSCopying>

@property (nonatomic, assign) NSInteger age;

- (void)animalInstanceMethod;
+ (void)animalClassMethod;

@end

///  Animal+Function1.m

#import "Animal+Function1.h"

@implementation Animal (Function1)

- (void)run {
    NSLog(@"Function1 --- run");
}

- (void)animalInstanceMethod {
    NSLog(@"Function1 --- animalInstanceMethod");
}

+ (void)animalClassMethod {

}

- (NSInteger)age {
    return 10;
}

- (void)setAge:(NSInteger)age {

}

- (nonnull id)copyWithZone:(nullable NSZone *)zone {
    return [Animal new];
}

@end

///  Animal+Function2.h

@interface Animal (Function2)

@end

///  Animal+Function2.m

@implementation Animal (Function2)

- (void)run {
    NSLog(@"Function2 --- run");
}

@end

```

## 一、Category的实现原理

#### 1.1、Category的底层构造

先从源码[objc4-781](https://opensource.apple.com/tarballs/objc4/)中找出分类的定义，其构造如下：

```Objective-C
struct category_t {
    const char *name;   // 所属类的名字，通俗说就是谁的分类，这里就是谁的名字
    classref_t cls;     //
    struct method_list_t *instanceMethods;      // 实例方法列表
    struct method_list_t *classMethods;         // 类方法列表
    struct protocol_list_t *protocols;          // 协议方法列表
    struct property_list_t *instanceProperties; // 实例属性列表
    // Fields below this point are not always present on disk.
    struct property_list_t *_classProperties;   // 类实例属性列表（目前没有）

    method_list_t *methodsForMeta(bool isMeta) {// 如果是元类返回类方法列表，否则返回实例方法列表
        if (isMeta) return classMethods;
        else return instanceMethods;
    }

    property_list_t *propertiesForMeta(bool isMeta, struct header_info *hi);

    protocol_list_t *protocolsForMeta(bool isMeta) {// 如果是元类返回空(类协议目前不存在)，否则返回实例协议方法列表
        if (isMeta) return nullptr;
        else return protocols;
    }
};
```

然后利用命名将*Animal+Function1.m*分类文件转换成底层c++文件，内部可发现相应的分类定义，其构造如下：

```Objective-C
struct _category_t {
    const char *name;
    struct _class_t *cls;
    const struct _method_list_t *instance_methods;
    const struct _method_list_t *class_methods;
    const struct _protocol_list_t *protocols;
    const struct _prop_list_t *properties;
};
```

对比之下发现少了部分，这不重要，命令生成的不是最新的形式，只是帮助我们来研究相应的一些内容。

下面先简单介绍一部分类型，以便理清分类的整体实现构造。
利用命令生成的代码名会比源码中找到的会多出个下划线（比如 iOS的私有类名就会以下划线开头）

- *objc_method*的定义

源码：

```Objective-C
struct objc_method {
    SEL _Nonnull method_name                                 OBJC2_UNAVAILABLE;
    char * _Nullable method_types                            OBJC2_UNAVAILABLE;
    IMP _Nonnull method_imp                                  OBJC2_UNAVAILABLE;
}                                                            OBJC2_UNAVAILABLE;
```

命令生成：

```Objective-C
struct _objc_method {
    struct objc_selector * _cmd;
    const char *method_type;
    void  *_imp;
};
```

objc_selector * 和 SEL 是等价的，其源码描述如下：

```Objective-C
/// An opaque type that represents a method selector.
typedef struct objc_selector *SEL; 
```

类型*objc_selector*源码中没有给出具体的实现，但是从[GNU](http://www.gnustep.org/resources/downloads.php)中有大致的相关实现，以供参考。

GNU中*objc_selector*定义如下：

```Objective-C
/**
* Structure used to store selectors in the list.
*/
struct objc_selector
{
    union
    {
        /**
        * The name of this selector.  Used for unregistered selectors.
        */
        const char *name;
        /**
        * The index of this selector in the selector table.  When a selector
        * is registered with the runtime, its name is replaced by an index
        * uniquely identifying this selector.  The index is used for dispatch.
        */
        uintptr_t index;
    };
    /**
    * The Objective-C type encoding of the message identified by this selector.
    */
    const char * types;
};
```

在iOS平台定义可能不同，**暂时可以将SEL看成char *类型**，原因如下：

```Objective-C
SEL selector = @selector(animalClassMethod);
NSLog(@"%s", selector);
/// 输出结果：animalClassMethod
```

首先SEL是一个结构体，如果直接打印结构体将会打印第一个成员变量。以GNU 中*objc_selector*的定义为例,验证如下：

```Objective-C
struct objc_selector *s = {{"firstVar"}, 100};
NSLog(@"%s", s);
/// 输出结果：firstVar
```

IMP 就是一个函数指针，其在源码中的定义如下：

```Objective-C
typedef void (*IMP)(void /* id, SEL, ... */ ); 
```
上面已明确指出，IMP一定包括id和SEL类型，也就是说方法内部会包含两个隐藏的参数self和_cmd，它们的类型就是对应的id和SEL
验证如下:

```Objective-C

// 获取selector
SEL selector = @selector(animalInstanceMethod);
// 获取animal中对应selector的方法实现
IMP imp = [animal methodForSelector: selector];
// 构造一个和IMP一样的函数指针，参数必须包括id和SEL两个参数,少则报错，多不影响
void (*func)(id, SEL) = (void *)imp;
// 下面故意将两个参数的值修改成其它
func(@"test", @selector(run));

- (void)animalInstanceMethod {
    NSLog(@"%@--%s", self, _cmd);
    /// 输出结果：test--run
}

```

另外Clang命令生成的方法中也可验证，代码展示如下：

```
static void _I_Animal_Function1_run(Animal * self, SEL _cmd) {
    NSLog((NSString *)&__NSConstantStringImpl__var_folders_ds_rx2r4gh92f90vnk3_x0v2qcc0000gn_T_Animal_Function1_c6f528_mi_0);
}

static void _I_Animal_Function1_animalInstanceMethod(Animal * self, SEL _cmd) {
    NSLog((NSString *)&__NSConstantStringImpl__var_folders_ds_rx2r4gh92f90vnk3_x0v2qcc0000gn_T_Animal_Function1_c6f528_mi_1);
}

static void _C_Animal_Function1_animalClassMethod(Class self, SEL _cmd) {

}

static NSInteger _I_Animal_Function1_age(Animal * self, SEL _cmd) {
    return 10;
}

static void _I_Animal_Function1_setAge_(Animal * self, SEL _cmd, NSInteger age) {

}

static id _Nonnull _I_Animal_Function1_copyWithZone_(Animal * self, SEL _cmd, NSZone * _Nullable zone) {
    return ((Animal *(*)(id, SEL))(void *)objc_msgSend)((id)objc_getClass("Animal"), sel_registerName("new"));
}

```
每一个方法的参数一定包含一个对象self(在这里类型是`Animal`), 和一个_cmd变量。


总结一下：

- SEL: selector的简写, 方法选择器,实质存储的是方法的名称
- IMP: implement的简写, 方法实现,源码中它就是一个函数指针
- method_type: 描述方法的参数和返回值类型

#### 1.2、prop_t属性定义

源码中没有发现`prop_t`的定义。

命令生成：

```Objective-C
struct _prop_t {
    const char *name;
    const char *attributes;
};

```
由上看出属性包含了名字和特征两个字段。
名字即为代码中出现的属性名。例如 `@property (nonatomic, assign) NSInteger age;`这是name = age
特征表明这个属性是什么类型和有哪些修饰关键字，例如：`{"age","Tq,N"}` 中 `T -> Type` ，`q -> long long` , `N -> nonatomic`等


#### 1.3、分类的构造

利用clang生成的代码中可以发现 分类`Animal+Function2.m`的的定义，如下图展示：

![category.png](https://upload-images.jianshu.io/upload_images/1846524-713588a5e0d3131a.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

从上图可以发现
OC的底层生成了一个名为 `_OBJC_$_CATEGORY_Animal_$_Function1`类型为`struct _category_t*`的变量，`_OBJC_$_CATEGORY_Animal_$_Function1` 变量的值已经被对应的数据进行填充。

下面展示下对应的数据

- ###### name
`Animal_$_Function1`的原类为`Animal`,所以这里的值 是`Animal`

- ###### cls
classref_t 的定义如下
```Objective-C
// classref_t is unremapped class_t*  // classref_t是未进行重新映射的class_t
typedef struct classref * classref_t;
```
`class_t`的实现源码中并未公开，不过在Clang生成的源码中可以发现可能过时的定义(说过期是因为可能内部的构造被更改了)
```Objective-C
struct _class_t {
    struct _class_t *isa;
    struct _class_t *superclass;
    void *cache;
    void *vtable;
    struct _class_ro_t *ro;
};
```
前三项是和`objc_class`结构体的定义保持一致

- ###### instanceMethods

instanceMethods 的值被 `_OBJC_$_CATEGORY_INSTANCE_METHODS_Animal_$_Function1` 变量填充，其定义如下：
```Objective-C
static struct /*_method_list_t*/ {
    unsigned int entsize;                // sizeof(struct _objc_method)，每个方法结构体占用的大小，利用 method_count * entsize即得出所有方法占用的空间
    unsigned int method_count;           // 包含的方法数量
    struct _objc_method method_list[5];  // _objc_method 类型上面已经描述过 
} _OBJC_$_CATEGORY_INSTANCE_METHODS_Animal_$_Function1 __attribute__ ((used, section ("__DATA,__objc_const"))) = {
    sizeof(_objc_method),
    5,
    {{(struct objc_selector *)"run", "v16@0:8", (void *)_I_Animal_Function1_run},
    {(struct objc_selector *)"animalInstanceMethod", "v16@0:8", (void *)_I_Animal_Function1_animalInstanceMethod},
    {(struct objc_selector *)"age", "q16@0:8", (void *)_I_Animal_Function1_age},
    {(struct objc_selector *)"setAge:", "v24@0:8q16", (void *)_I_Animal_Function1_setAge_},
    {(struct objc_selector *)"copyWithZone:", "@24@0:8^{_NSZone=}16", (void *)_I_Animal_Function1_copyWithZone_}}
};
```
上述代码中下面一部分可以看出分类中包含的`run` 、`animalInstanceMethod`， `age`， `setAge:`， `copyWithZone` 五个实例方法以及对应的方法类型和方法实现


- ###### classMethods

classMethods 的结构和instanceMethods是一致的，具体可以查看下面的源码

```Objective-C
static struct /*_method_list_t*/ {
    unsigned int entsize;  // sizeof(struct _objc_method)
    unsigned int method_count;
    struct _objc_method method_list[1];
} _OBJC_$_CATEGORY_CLASS_METHODS_Animal_$_Function1 __attribute__ ((used, section ("__DATA,__objc_const"))) = {
    sizeof(_objc_method),
    1,
    {{(struct objc_selector *)"animalClassMethod", "v16@0:8", (void *)_C_Animal_Function1_animalClassMethod}}
};
```
- ###### protocols

首先简单介绍下_protocol_t
源码中protocol_t的定义如下(定义特别长，只截取部分展示)：
```Objective-C
struct protocol_t : objc_object {
    const char *mangledName;
    struct protocol_list_t *protocols;
    method_list_t *instanceMethods;
    method_list_t *classMethods;
    method_list_t *optionalInstanceMethods;
    method_list_t *optionalClassMethods;
    property_list_t *instanceProperties;
    uint32_t size;   // sizeof(protocol_t)
    uint32_t flags;
    // Fields below this point are not always present on disk.
    const char **_extendedMethodTypes;
    const char *_demangledName;
    property_list_t *_classProperties;

    const char *demangledName();

    const char *nameForLogging() {
    return demangledName();
}
```

从上面可以看出 它是继承`objc_object`，所以具备`objc_object`的一些特性


```Objective-C
static struct /*_protocol_list_t*/ {
    long protocol_count;  // Note, this is 32/64 bit
    struct _protocol_t *super_protocols[1];
} _OBJC_CATEGORY_PROTOCOLS_$_Animal_$_Function1 __attribute__ ((used, section ("__DATA,__objc_const"))) = {
    1,
    &_OBJC_PROTOCOL_NSCopying
};

struct _protocol_t _OBJC_PROTOCOL_NSCopying __attribute__ ((used)) = {
    0,  // isa指针为空                    
    "NSCopying",   // 协议名
    0,             // 协议列表为空
    (const struct method_list_t *)&_OBJC_PROTOCOL_INSTANCE_METHODS_NSCopying,   // 协议目前只有一个实例方法
    0,             // 类方法列表为空
    0,             // 可选实例方法列表为空
    0,             // 可选类方法列表为空
    0,             // 实例属性列表为空
    sizeof(_protocol_t), // _protocol_t占用大小
    0,             // flags
    (const char **)&_OBJC_PROTOCOL_METHOD_TYPES_NSCopying // 方法类型列表
};
```

- ###### properties

变量`_OBJC_$_PROP_LIST_Animal_$_Function1`在Clang中的定义如下：

```Objective-C
static struct /*_prop_list_t*/ {
    unsigned int entsize;  // sizeof(struct _prop_t)
    unsigned int count_of_properties;
    struct _prop_t prop_list[1];
} _OBJC_$_PROP_LIST_Animal_$_Function1 __attribute__ ((used, section ("__DATA,__objc_const"))) = {
    sizeof(_prop_t),    
    1,
    {{"age","Tq,N"}}
};
```

下面以一张对分类的结构做个总结

![category结构图.jpg](https://upload-images.jianshu.io/upload_images/1846524-30b244e8bb546e2d.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

#### 1.4、分类的加载过程

首先在源码中`objc-os.mm`文件中的有下述一段源码

- _objc_init

```Objective-C
/***********************************************************************
* _objc_init
* Bootstrap initialization. Registers our image notifier with dyld.
* Called by libSystem BEFORE library initialization time
**********************************************************************/
// _objc_init的加载过程 Bootstrap（boot 本意靴子意为引导，strap 动词打绷带）
void _objc_init(void)
{
    static bool initialized = false;
    if (initialized) return;
    initialized = true;

    // fixme defer initialization until an objc-using image is found?
    environ_init();
    tls_init();
    static_init();
    runtime_init();
    exception_init();
    cache_init();
    _imp_implementationWithBlock_init();


    _dyld_objc_notify_register(&map_images, load_images, unmap_image);

    #if __OBJC2__
        didCallDyldNotifyRegister = true;
    #endif
}
```

由上看出动态链接器`dyld`中的私有方法 `_dyld_objc_notify_register`被传入了一个 `map_images`函数指针，这个函数指针就是用来加载模块的。另外 `_dyld_objc_notify_register`主要是注册要在`mapped`、`unmapped`和`initialized`的回调。其实都是函数指针，只不过会在合适的进行调用。

-  map_images 函数

```Objective-C
void map_images(unsigned count, const char * const paths[],
                const struct mach_header * const mhdrs[]) 
{
    mutex_locker_t lock(runtimeLock);
    return map_images_nolock(count, paths, mhdrs);
}

```

map_images 函数内部调用了`map_images_nolock`,并传入相应的mach-o header信息。

-  map_images_nolock 函数

这里源码比较长，下面截取研究分类流程部分

```
void 
map_images_nolock(unsigned mhCount, const char * const mhPaths[],
                 const struct mach_header * const mhdrs[])
{

    static bool firstTime = YES;
    header_info *hList[mhCount];
    uint32_t hCount;
    size_t selrefCount = 0;

    // Perform first-time initialization if necessary.
    // This function is called before ordinary library initializers. 
    // fixme defer initialization until an objc-using image is found?
    if (firstTime) {
        preopt_init();
    }

    if (PrintImages) {
        _objc_inform("IMAGES: processing %u newly-mapped images...\n", mhCount);
    }


    // Find all images with Objective-C metadata. 
    hCount = 0;

    // Count classes. Size various table based on the total.
    // 找出所有的类，并以此确定确定表的大小
    int totalClasses = 0;
    int unoptimizedTotalClasses = 0;
    {
        uint32_t i = mhCount;
        while (i--) {
            const headerType *mhdr = (const headerType *)mhdrs[i];
            
            auto hi = addHeader(mhdr, mhPaths[i], totalClasses, unoptimizedTotalClasses);
            if (!hi) {
                // no objc data in this entry
                continue;
            }
            
            /**************
                省略代码
            **************/
            
            hList[hCount++] = hi;
            
            /**************
                省略代码
            **************/
        }
    }
    
    /**************
        省略代码
    **************/
    
    // 这里根据计算出的数据进行模块的读取
    if (hCount > 0) {
        _read_images(hList, hCount, totalClasses, unoptimizedTotalClasses);
    }
    
    /**************
        省略代码
    **************/
}
```
-  _read_images 函数


```
void _read_images(header_info **hList, uint32_t hCount, int totalClasses, int unoptimizedTotalClasses)
{
    header_info *hi;
    uint32_t hIndex;
    size_t count;
    size_t i;
    Class *resolvedFutureClasses = nil;
    size_t resolvedFutureClassCount = 0;
    static bool doneOnce;
    bool launchTime = NO;
    TimeLogger ts(PrintImageTimes);

    runtimeLock.assertLocked();

    // 这里主要是定义一个遍历的局部宏
#define EACH_HEADER \
    hIndex = 0;         \
    hIndex < hCount && (hi = hList[hIndex]); \
    hIndex++
    
    /**************
        省略代码
    **************/
    
    
    // Discover categories. Only do this after the initial category
    // attachment has been done. For categories present at startup,
    // discovery is deferred until the first load_images call after
    // the call to _dyld_objc_notify_register completes. rdar://problem/53119145
    // 上面注释已经说清楚了只有在load_images处理完之后，才会处理下面的代码。
    // 另外load_images函数也是_dyld_objc_notify_register的方法回调
    if (didInitialAttachCategories) {
        for (EACH_HEADER) {
            load_categories_nolock(hi);
        }
    }
    
    /**************
    省略代码
    **************/
}
```

上面有部分处理分类的代码，其中`didInitialAttachCategories`变量值默认是false,它只有在load_images中才会变成true，源码展示如下：


```
static bool didInitialAttachCategories = false;

void
load_images(const char *path __unused, const struct mach_header *mh)
{
    if (!didInitialAttachCategories && didCallDyldNotifyRegister) {
        didInitialAttachCategories = true;
        loadAllCategories();
    }

    // Return without taking locks if there are no +load methods here.
    if (!hasLoadMethods((const headerType *)mh)) return;

    recursive_mutex_locker_t lock(loadMethodLock);

    // Discover load methods
    {
        mutex_locker_t lock2(runtimeLock);
        prepare_load_methods((const headerType *)mh);
    }

    // Call +load methods (without runtimeLock - re-entrant)
    // 处理 load方法的调用
    call_load_methods();
}

```

- load_categories_nolock 函数

接下来进入`load_categories_nolock`函数，这里主要装载分类。

```
static void load_categories_nolock(header_info *hi) {

    bool hasClassProperties = hi->info()->hasCategoryClassProperties();

    size_t count;
    auto processCatlist = [&](category_t * const *catlist) {
        for (unsigned i = 0; i < count; i++) {
            ....
            省略代码
            ....
            // Process this category.
            if (cls->isStubClass()) {
                /**************
                    省略代码
                **************/
            } else {
                // 这里处理分类的实例方法，attachCategories是最终处理分类的方法
                if (cat->instanceMethods ||  cat->protocols
                    ||  cat->instanceProperties)
                {
                    if (cls->isRealized()) {
                        attachCategories(cls, &lc, 1, ATTACH_EXISTING);
                    } else {
                        objc::unattachedCategories.addForClass(lc, cls);    
                    }
                }
                
                // 这里处理分类的类方法，attachCategories是最终处理分类的方法
                if (cat->classMethods  ||  cat->protocols
                    ||  (hasClassProperties && cat->_classProperties))
                {
                    if (cls->ISA()->isRealized()) {
                        attachCategories(cls->ISA(), &lc, 1, ATTACH_EXISTING | ATTACH_METACLASS);
                    } else {
                        objc::unattachedCategories.addForClass(lc, cls->ISA());
                    }
                }
            }
            
        }
    }
    processCatlist(_getObjc2CategoryList(hi, &count));
    processCatlist(_getObjc2CategoryList2(hi, &count));
}
```

- attachCategories函数

源码和相关解释如下

```

// Attach method lists and properties and protocols from categories to a class.
// Assumes the categories in cats are all loaded and sorted by load order, 
// oldest categories first.
static void
attachCategories(Class cls, const locstamped_category_t *cats_list, uint32_t cats_count,
                int flags)
{
    if (slowpath(PrintReplacedMethods)) {
        printReplacements(cls, cats_list, cats_count);
    }
    if (slowpath(PrintConnecting)) {
        _objc_inform("CLASS: attaching %d categories to%s class '%s'%s",
        cats_count, (flags & ATTACH_EXISTING) ? " existing" : "",
        cls->nameForLogging(), (flags & ATTACH_METACLASS) ? " (meta)" : "");
    }

    /*
    * Only a few classes have more than 64 categories during launch.
    * This uses a little stack, and avoids malloc.
    *
    * Categories must be added in the proper order, which is back
    * to front. To do that with the chunking, we iterate cats_list
    * from front to back, build up the local buffers backwards,
    * and call attachLists on the chunks. attachLists prepends the
    * lists, so the final result is in the expected order.
    */
    constexpr uint32_t ATTACH_BUFSIZ = 64;
    method_list_t   *mlists[ATTACH_BUFSIZ];
    property_list_t *proplists[ATTACH_BUFSIZ];
    protocol_list_t *protolists[ATTACH_BUFSIZ];

    uint32_t mcount = 0;
    uint32_t propcount = 0;
    uint32_t protocount = 0;
    bool fromBundle = NO;
    bool isMeta = (flags & ATTACH_METACLASS);
    auto rwe = cls->data()->extAllocIfNeeded();

    for (uint32_t i = 0; i < cats_count; i++) {
        auto& entry = cats_list[i];

        method_list_t *mlist = entry.cat->methodsForMeta(isMeta);
        if (mlist) {
            if (mcount == ATTACH_BUFSIZ) {
                prepareMethodLists(cls, mlists, mcount, NO, fromBundle);
                rwe->methods.attachLists(mlists, mcount);
                mcount = 0;
            }
            mlists[ATTACH_BUFSIZ - ++mcount] = mlist;
            fromBundle |= entry.hi->isBundle();
        }

        property_list_t *proplist =
        entry.cat->propertiesForMeta(isMeta, entry.hi);
        if (proplist) {
            if (propcount == ATTACH_BUFSIZ) {
                rwe->properties.attachLists(proplists, propcount);
                propcount = 0;
            }
            proplists[ATTACH_BUFSIZ - ++propcount] = proplist;
        }

        protocol_list_t *protolist = entry.cat->protocolsForMeta(isMeta);
        if (protolist) {
            if (protocount == ATTACH_BUFSIZ) {
                rwe->protocols.attachLists(protolists, protocount);
                protocount = 0;
            }
            protolists[ATTACH_BUFSIZ - ++protocount] = protolist;
        }
    }

    if (mcount > 0) {
        prepareMethodLists(cls, mlists + ATTACH_BUFSIZ - mcount, mcount, NO, fromBundle);
        rwe->methods.attachLists(mlists + ATTACH_BUFSIZ - mcount, mcount);
        if (flags & ATTACH_EXISTING) flushCaches(cls);
    }

    rwe->properties.attachLists(proplists + ATTACH_BUFSIZ - propcount, propcount);

    rwe->protocols.attachLists(protolists + ATTACH_BUFSIZ - protocount, protocount);
}
```
`attachCategories`函数的注释中已经说明了，这是会将分类的方法列表、属性和协议添加到类中，最后加载的类会放在列表的最前面。
这里方法列表、属性列表和协议列表都会事先分配一个包含ATTACH_BUFSIZ = 64个元素的数组，也就是说在启动阶段最大的限制是64。
方法列表的插入会从数组的最末尾开始，也就是序号为63的开始，依次直至到序号为0。
源码中 `methods`、 `properties`， `protocols`最终都会调用`attachLists`方法，这里会将分类最终添加到相应的列表上。
`attachLists`参数会把数组中实际存入的数据传入，
例如 方法列表
`mlists` 占用的数量大小为`TTACH_BUFSIZ = 64`，`mcount`是总共包含的方法数， `ATTACH_BUFSIZ - mcount` 则为数组中空元素的最大序号，
`mlists + ATTACH_BUFSIZ - mcount` 则是定位到了第一个非空元素的位置。

-  attachLists 函数

下面是将分类中的数据拼接到类上的具体操作，源码如下：

```
void attachLists(List* const * addedLists, uint32_t addedCount) {
    if (addedCount == 0) return;

    if (hasArray()) {
        // many lists -> many lists
        uint32_t oldCount = array()->count;
        uint32_t newCount = oldCount + addedCount;
        setArray((array_t *)realloc(array(), array_t::byteSize(newCount)));
        array()->count = newCount;
        memmove(array()->lists + addedCount, array()->lists, 
        oldCount * sizeof(array()->lists[0]));
        memcpy(array()->lists, addedLists, addedCount * sizeof(array()->lists[0]));
    }
    else if (!list  &&  addedCount == 1) {
        // 0 lists -> 1 list
        list = addedLists[0];
    } 
    else {
        // 1 list -> many lists
        List* oldList = list;
        uint32_t oldCount = oldList ? 1 : 0;
        uint32_t newCount = oldCount + addedCount;
        setArray((array_t *)malloc(array_t::byteSize(newCount)));
        array()->count = newCount;
        if (oldList) array()->lists[addedCount] = oldList;
        memcpy(array()->lists, addedLists, addedCount * sizeof(array()->lists[0]));
    }
}
```

列表的拼接分了三种情况，
- 1：lists列表中存在多条数据，
- 2：lists中列表只存在一个元素，
- 3：lists列表中不存在数据且addedLists列表只有一个元素， 

对于情况3，只需要取出addedLists列表中的首个元素赋给lists列表即可

对于情况1，逻辑展示如下图：
![c1](https://upload-images.jianshu.io/upload_images/1846524-c9464573d701fa9d.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

对于情况2，逻辑展示如下图：
![c2](https://upload-images.jianshu.io/upload_images/1846524-be7ee224ac4e43ff.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

- 一个注意点

在设置分类列表的时候，会出现`setArray` 、`hasArray`等相关方法,如下图

```
bool hasArray() const {
    return arrayAndFlag & 1;
}

array_t *array() const {
    return (array_t *)(arrayAndFlag & ~1);
}

void setArray(array_t *array) {
    arrayAndFlag = (uintptr_t)array | 1;
}
```

在`setArray`的时候会取出参数`array`的地址，然后将最后一位置1,在取`array`的时候（ 调用`array()` ），又会将最后一位复位，有一个疑问就是在置位的时候如果地址的最后一位是个1，然后再调用array()的时候不就出现了问题。
其实这个问题不会出现。原因是内存对齐和arrayAndFlag的类型是`uintptr_t`，它占用4个字节，即偶数个字节，所以在内存对齐的时候，分配给`arrayAndFlag`的地址必然是2的倍数，所以地址的最后一位一定是0。如果类型占用奇数个字节就会可能出现地址为1的情况，比如：char类型

到此，分类的加载过程结束
