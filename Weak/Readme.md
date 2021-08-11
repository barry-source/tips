
# Weak底层原理

## 1、Weak相关结构


### 1.1、weak编译解析

首先需要看一下weak编译之后具体出现什么样的变化，通过Clang的方法把weak编译成C++

```ruby
int main(){
    NSObject *obj = [[NSObject alloc] init];
    id __weak obj1 = obj;
}
```
编译之后的weak展现形式
```
int main(){
    NSObject *obj = ((NSObject *(*)(id, SEL))(void *)objc_msgSend)((id)((NSObject *(*)(id, SEL))(void *)objc_msgSend)((id)objc_getClass("NSObject"), sel_registerName("alloc")), sel_registerName("init"));
    id __attribute__((objc_ownership(weak))) obj1 = obj;
}
```

通过`objc_ownership(weak)`实现`weak`方法，`objc_ownership`字面意思是：获得对象的所有权，是对对象weak的初始化的一个操作。

> 在使用clang编译过程中会报错误，使用下方的方法编码编译出现error
clang -rewrite-objc -fobjc-arc -stdlib=libc++ -mmacosx-version-min=10.7 -fobjc-runtime=macosx-10.7 -Wno-deprecated-declarations main.m


### 1.2、Weak的实现原理

第一、通过weak编译解析，可以看出来weak通过runtime初始化的并维护的；
第二、weak和strong都是Object-C的修饰词，而strong是通过runtime维护的一个自动计数表结构。

综上：weak是有Runtime维护的weak表。

在runtime源码中，可以找到`objc-weak.h`和`objc-weak.mm`文件，并且在`objc-weak.h`文件中关于定义weak表的结构体以及相关的方法。

### 1.3、Weak表

`weak_table_t`是一个全局weak 引用的表，使用对象的地址作为 key，用 `weak_entry_t` 类型结构体对象作为 value 。其中的 `weak_entries `成员

`weak_table_t`结构如下所示：
```ruby
/**
 * The global weak references table. Stores object ids as keys,
 * and weak_entry_t structs as their values.
 */
struct weak_table_t {
    weak_entry_t *weak_entries;         // 保存了所有指向特定对象的weak指针   weak_entries的对象
    size_t    num_entries;              // weak对象的存储空间
    uintptr_t mask;                     // 参与判断引用计数辅助量
    uintptr_t max_hash_displacement;    // hash key 最大偏移值
};
```
其中`weak_entry_t`是存储在弱引用表中的一个内部结构体，它负责维护和存储指向某一个对象的所有弱引用hash表。
其定义如下：
```ruby
typedef objc_object ** weak_referrer_t;
struct weak_entry_t {
    DisguisedPtr<objc_object> referent;  //范型
    union {
        struct {
            weak_referrer_t *referrers;
            uintptr_t        out_of_line : 1;
            uintptr_t        num_refs : PTR_MINUS_1;
            uintptr_t        mask;
            uintptr_t        max_hash_displacement;
        };
        struct {
            // out_of_line=0 is LSB of one of these (don't care which)
            weak_referrer_t  inline_referrers[WEAK_INLINE_COUNT];
        };
    }
}
```

总之：
1.`weak_table_t`(weak 全局表)：采用hash（哈希表）的方式把所有weak引用的对象，存储所有引用weak对象
2`.weak_entry_t`（weak_table_t表中hash表的value值，weak对象体）：用于记录hash表中weak对象
3.`objc_object`（weak_entry_t对象中的范型对象，用于标记对象weak对象）：用于标示weak引用的对象。

详细讲解weak存储对象结构，对接下来对weak操作使用可以更加清晰的理解weak的使用。

## 2、Weak底层原理

### 2.1.weak底层实现原理

在runtime源码中的`NSObject.mm`文件中找到了关于初始化和管理weak表的方法

### `初始化weak表方法`

```ruby
/** 
 * Initialize a fresh weak pointer to some object location. 
 * It would be used for code like: 
 *
 * (The nil case) 
 * __weak id weakPtr;
 * (The non-nil case) 
 * NSObject *o = ...;
 * __weak id weakPtr = o;
 * 
 * @param addr Address of __weak ptr. 
 * @param val Object ptr. 
 */
 
 // 上述注释已经写明了，objc_initWeak不是线程安全的，weak的置空是线程安全的
 
 id objc_initWeak(id *location, id newObj)
 {
     if (!newObj) {
         *location = nil;
         return nil;
     }

     return storeWeak<DontHaveOld, DoHaveNew, DoCrashIfDeallocating>
         (location, (objc_object*)newObj);
 }

/************************************************************/

static id storeWeak(id *location, objc_object *newObj)
{
    ASSERT(haveOld  ||  haveNew);
    if (!haveNew) ASSERT(newObj == nil);

    Class previouslyInitializedClass = nil;
    id oldObj;
    SideTable *oldTable;
    SideTable *newTable;

    // Acquire locks for old and new values.
    // Order by lock address to prevent lock ordering problems. 
    // Retry if the old value changes underneath us.
 retry:
    if (haveOld) {
        oldObj = *location;
        oldTable = &SideTables()[oldObj];
    } else {
        oldTable = nil;
    }
    if (haveNew) {
        newTable = &SideTables()[newObj];
    } else {
        newTable = nil;
    }

    SideTable::lockTwo<haveOld, haveNew>(oldTable, newTable);

    if (haveOld  &&  *location != oldObj) {
        SideTable::unlockTwo<haveOld, haveNew>(oldTable, newTable);
        goto retry;
    }

    // Prevent a deadlock between the weak reference machinery
    // and the +initialize machinery by ensuring that no 
    // weakly-referenced object has an un-+initialized isa.
    if (haveNew  &&  newObj) {
        Class cls = newObj->getIsa();
        if (cls != previouslyInitializedClass  &&  
            !((objc_class *)cls)->isInitialized()) 
        {
            SideTable::unlockTwo<haveOld, haveNew>(oldTable, newTable);
            class_initialize(cls, (id)newObj);

            // If this class is finished with +initialize then we're good.
            // If this class is still running +initialize on this thread 
            // (i.e. +initialize called storeWeak on an instance of itself)
            // then we may proceed but it will appear initializing and 
            // not yet initialized to the check above.
            // Instead set previouslyInitializedClass to recognize it on retry.
            previouslyInitializedClass = cls;

            goto retry;
        }
    }

    // Clean up old value, if any.
    if (haveOld) {
        weak_unregister_no_lock(&oldTable->weak_table, oldObj, location);
    }

    // Assign new value, if any.
    if (haveNew) {
        newObj = (objc_object *)
            weak_register_no_lock(&newTable->weak_table, (id)newObj, location, 
                                  crashIfDeallocating ? CrashIfDeallocating : ReturnNilIfDeallocating);
        // weak_register_no_lock returns nil if weak store should be rejected

        // Set is-weakly-referenced bit in refcount table.
        if (!newObj->isTaggedPointerOrNil()) {
            newObj->setWeaklyReferenced_nolock();
        }

        // Do not set *location anywhere else. That would introduce a race.
        *location = (id)newObj;
    }
    else {
        // No new value. The storage is not changed.
    }
    
    SideTable::unlockTwo<haveOld, haveNew>(oldTable, newTable);

    // This must be called without the locks held, as it can invoke
    // arbitrary code. In particular, even if _setWeaklyReferenced
    // is not implemented, resolveInstanceMethod: may be, and may
    // call back into the weak reference machinery.
    callSetWeaklyReferenced((id)newObj);
//    printf("%d", newTable->weak_table.weak_entries[0]);
    return (id)newObj;
}
```
上述代码的流程图：

![weak](https://upload-images.jianshu.io/upload_images/2664540-255e050c9fafa044.png?imageMogr2/auto-orient/strip|imageView2/2/w/553)


另外SideTable的结构如下，它包含了弱引用表。

```ruby
struct SideTable {
    spinlock_t slock;
    RefcountMap refcnts;
    weak_table_t weak_table;

    SideTable() {
        memset(&weak_table, 0, sizeof(weak_table));
    }

    ~SideTable() {
        _objc_fatal("Do not delete SideTable.");
    }

    void lock() { slock.lock(); }
    void unlock() { slock.unlock(); }
    void forceReset() { slock.forceReset(); }

    // Address-ordered lock discipline for a pair of side tables.

    template<HaveOld, HaveNew>
    static void lockTwo(SideTable *lock1, SideTable *lock2);
    template<HaveOld, HaveNew>
    static void unlockTwo(SideTable *lock1, SideTable *lock2);
};
```

总上所有流程如下图；

![流程](https://upload-images.jianshu.io/upload_images/2664540-2d3b53046d67d907.png?imageMogr2/auto-orient/strip|imageView2/2/w/600)

### 2.2、weak自动设置为nil的过程

weak被释放为nil，需要对对象整个释放过程了解，如下是对象释放的整体流程：
1、调用objc_release

2、因为对象的引用计数为0，所以执行dealloc

3、在dealloc中，调用了_objc_rootDealloc函数

4、在_objc_rootDealloc中，调用了object_dispose函数

5、调用objc_destructInstance

6、最后调用objc_clear_deallocating。

对象准备释放时，调用clearDeallocating函数。clearDeallocating函数首先根据对象地址获取所有weak指针地址的数组，然后遍历这个数组把其中的数据设为nil，最后把这个entry从weak表中删除，最后清理对象的记录。

在对象被释放的流程中，需要对objc_clear_deallocating方法进行深入的分析

```
void objc_clear_deallocating(id obj) 
{
    ASSERT(obj);

    if (obj->isTaggedPointer()) return;
    obj->clearDeallocating();
}

/*******
    省略部分函数调用
**/

// 这是最终执行weak清空的函数
void weak_clear_no_lock(weak_table_t *weak_table, id referent_id) 
{
    objc_object *referent = (objc_object *)referent_id;

    weak_entry_t *entry = weak_entry_for_referent(weak_table, referent);
    if (entry == nil) {
        /// XXX shouldn't happen, but does with mismatched CF/objc
        //printf("XXX no entry for clear deallocating %p\n", referent);
        return;
    }

    // zero out references
    weak_referrer_t *referrers;
    size_t count;
    
    if (entry->out_of_line()) {
        referrers = entry->referrers;
        count = TABLE_SIZE(entry);
    } 
    else {
        referrers = entry->inline_referrers;
        count = WEAK_INLINE_COUNT;
    }
    
    for (size_t i = 0; i < count; ++i) {
        objc_object **referrer = referrers[i];
        if (referrer) {
            if (*referrer == referent) {
                *referrer = nil;
            }
            else if (*referrer) {
                _objc_inform("__weak variable at %p holds %p instead of %p. "
                             "This is probably incorrect use of "
                             "objc_storeWeak() and objc_loadWeak(). "
                             "Break on objc_weak_error to debug.\n", 
                             referrer, (void*)*referrer, (void*)referent);
                objc_weak_error();
            }
        }
    }
    
    weak_entry_remove(weak_table, entry);
}

```
objc_clear_deallocating该函数的动作如下：

1、从weak表中获取废弃对象的地址为键值的记录

2、将包含在记录中的所有附有 weak修饰符变量的地址，赋值为nil

3、将weak表中该记录删除

4、从引用计数表中删除废弃对象的地址为键值的记录

其实Weak表是一个hash（哈希）表，然后里面的key是指向的对象地址，Value是Weak指针的地址数组。

总结

weak是Runtime维护了一个hash(哈希)表，用于存储指向某个对象的所有weak指针。weak表其实是一个hash（哈希）表，Key是所指对象的地址，Value是weak指针的地址（这个地址的值是所指对象指针的地址）数组。
