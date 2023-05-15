/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIView+WebCacheOperation.h"
#import "objc/runtime.h"

// key is strong, value is weak because operation instance is retained by SDWebImageManager's runningOperations property
// we should use lock to keep thread-safe because these method may not be accessed from main queue
typedef NSMapTable<NSString *, id<SDWebImageOperation>> SDOperationsDictionary;

@implementation UIView (WebCacheOperation)

- (SDOperationsDictionary *)sd_operationDictionary
{
    @synchronized(self)
    {
        SDOperationsDictionary *operations = objc_getAssociatedObject(self, @selector(sd_operationDictionary));
        if (operations) {
            return operations;
        }
        // 初始为空时会强制设置一个关联对象
        operations = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsWeakMemory capacity:0];
        objc_setAssociatedObject(self, @selector(sd_operationDictionary), operations, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return operations;
    }
}

- (nullable id<SDWebImageOperation>)sd_imageLoadOperationForKey:(nullable NSString *)key
{
    id<SDWebImageOperation> operation;
    if (key) {
        SDOperationsDictionary *operationDictionary = [self sd_operationDictionary];
        @synchronized(self)
        {
            operation = [operationDictionary objectForKey:key];
        }
    }
    return operation;
}

- (void)sd_setImageLoadOperation:(nullable id<SDWebImageOperation>)operation forKey:(nullable NSString *)key
{
    if (key) {
        // 🎂删除旧operation
        [self sd_cancelImageLoadOperationWithKey:key];
        if (operation) {
            // 获取关联对象sd_operationDictionary，并将同步保存新operation
            SDOperationsDictionary *operationDictionary = [self sd_operationDictionary];
            @synchronized(self)
            {
                [operationDictionary setObject:operation forKey:key];
            }
        }
    }
}

- (void)sd_cancelImageLoadOperationWithKey:(nullable NSString *)key
{
    if (key) {
        // 获取关联对象sd_operationDictionary
        // Cancel in progress downloader from queue
        SDOperationsDictionary *operationDictionary = [self sd_operationDictionary];
        id<SDWebImageOperation> operation;
        // 同步获取operation
        @synchronized(self)
        {
            operation = [operationDictionary objectForKey:key];
        }
        if (operation) {
            // 如果实现了`SDWebImageOperation`协议中的cancle,把operation任务取消掉
            // ⚠️ NSOperation 本身有cancel方法，sd又在分类 NSOperation (SDWebImageOperation)中遵守了SDWebImageOperation协议，分类中的cancel有效
            if ([operation respondsToSelector:@selector(cancel)]) {
                [operation cancel];
            }
            // 同步移除operation
            @synchronized(self)
            {
                [operationDictionary removeObjectForKey:key];
            }
        }
    }
}

- (void)sd_removeImageLoadOperationWithKey:(nullable NSString *)key
{
    if (key) {
        SDOperationsDictionary *operationDictionary = [self sd_operationDictionary];
        @synchronized(self)
        {
            [operationDictionary removeObjectForKey:key];
        }
    }
}

@end
