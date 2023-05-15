
# SDWebImage 源码(5.15.7)分析


## 【step 1】sd_setImageWithURL

由于SDWebImage 添加了`UIImageView+WebCache`分类，所以可以直接在UIImageView的实例上调用图片加载方法, 分类里定义了一些`sd_setImageWithURL`相关的方法，最终这些方法都会调用到下面的方法
    
```
- (void)sd_setImageWithURL:(nullable NSURL *)url
          placeholderImage:(nullable UIImage *)placeholder
                   options:(SDWebImageOptions)options
                   context:(nullable SDWebImageContext *)context
                  progress:(nullable SDImageLoaderProgressBlock)progressBlock
                 completed:(nullable SDExternalCompletionBlock)completedBlock {
    // 这个方法是在`UIView+WebCache`分类内，这个分类里面定义了通用的一些属性和方法，因为不只是UIImageView在使用，像UIButton也在使用
    [self sd_internalSetImageWithURL:url
                    placeholderImage:placeholder
                             options:options
                             context:context
                       setImageBlock:nil
                            progress:progressBlock
                           completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL) {
                               if (completedBlock) {
                                   completedBlock(image, error, cacheType, imageURL);
                               }
                           }];
}

```

**注意点:**

- SDWebImageContext：这个类型是在5.0之后出现的，本质就是一个字典，如果外部未提供的话，内部会自动生成一个
- SDExternalCompletionBlock: 外部完成回调，相应的SDWebImage内部使用的是SDInternalCompletionBlock，两种回调的定义如下

    ```
    typedef void(^SDExternalCompletionBlock)(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL);
    typedef void(^SDInternalCompletionBlock)(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL);
    ```


## 【step 2】sd_internalSetImageWithURL

该方法代码存在于`UIView+WebCache`分类内，源码及注释如下所示

```
/// 给imageView设置图片
/// @param url 图片链接
/// @param placeholder 占位图
/// @param options 图片加载选项
/// @param context 配置项，NSDictionary
/// @param setImageBlock 设置图片 Block（基于 UIImageView 方式调用的该参数一般为 nil）
/// @param progressBlock 图片进度回调
/// @param completedBlock 图片完成回调 
- (nullable id<SDWebImageOperation>)sd_internalSetImageWithURL:(nullable NSURL *)url
                                              placeholderImage:(nullable UIImage *)placeholder
                                                       options:(SDWebImageOptions)options
                                                       context:(nullable SDWebImageContext *)context
                                                 setImageBlock:(nullable SDSetImageBlock)setImageBlock
                                                      progress:(nullable SDImageLoaderProgressBlock)progressBlock
                                                     completed:(nullable SDInternalCompletionBlock)completedBlock
{
    // 如果外部传入context，则对context做copy操作，防止改变，否则内部自动创建一个不可变的context
    if (context) {
        context = [context copy];
    }
    else {
        context = [NSDictionary dictionary];
    }
    // 获取OperationKey，在外部未传入context时，第一次取出就是nil
    NSString *validOperationKey = context[SDWebImageContextSetImageOperationKey];
    // OperationKey = nil 进入下面的操作
    if (!validOperationKey) {
        // 对于UIImageView实例来说，这里的self就是UIImageView
        validOperationKey = NSStringFromClass([self class]);
        // mutableCopy -> 存储 -> copy, 将OperationKey存入到context
        SDWebImageMutableContext *mutableContext = [context mutableCopy];
        mutableContext[SDWebImageContextSetImageOperationKey] = validOperationKey;
        context = [mutableContext copy];
    }
    // 将key保存到`UIImageView+WebCache`中的sd_latestOperationKey关联属性中
    self.sd_latestOperationKey = validOperationKey;
    // 取消上一次OperationKey对应的下载
    [self sd_cancelImageLoadOperationWithKey:validOperationKey];
    // 将url保存到`UIImageView+WebCache`中的sd_imageURL关联属性中
    self.sd_imageURL = url;

    // 和validOperationKey类似，在外部未传入context时，第一次取出时就是nil
    SDWebImageManager *manager = context[SDWebImageContextCustomManager];
    if (!manager) {
        manager = [SDWebImageManager sharedManager];
    }
    else {
        // 如果外部传入manager,context里要删除，避免内存泄漏
        // remove this manager to avoid retain cycle (manger -> loader -> operation -> context -> manager)
        SDWebImageMutableContext *mutableContext = [context mutableCopy];
        mutableContext[SDWebImageContextCustomManager] = nil;
        context = [mutableContext copy];
    }

    // 是否使用内存弱引用，5.12.0 之前默认是YES，之后是NO
    BOOL shouldUseWeakCache = NO;
    if ([manager.imageCache isKindOfClass:SDImageCache.class]) {
        shouldUseWeakCache = ((SDImageCache *)manager.imageCache).config.shouldUseWeakMemoryCache;
    }
    // 默认是要显示占位图，如果设置了SDWebImageDelayPlaceholder，则不显示占位图
    // ⚠️ SDWebImageDelayPlaceholder可以当作图片下载失败的占位图，而不是图片下载过程中的占位图，下载过程中不显示，下载失败时会显示
    if (!(options & SDWebImageDelayPlaceholder)) {
        // ⚠️ 触发弱引用存储，如下注释所示此结构可能要被删除
        if (shouldUseWeakCache) {
            NSString *key = [manager cacheKeyForURL:url context:context];
            // call memory cache to trigger weak cache sync logic, ignore the return value and go on normal query
            // this unfortunately will cause twice memory cache query, but it's fast enough
            // in the future the weak cache feature may be re-design or removed
            [((SDImageCache *)manager.imageCache) imageFromMemoryCacheForKey:key];
        }
        dispatch_main_async_safe(^{
          [self sd_setImage:placeholder imageData:nil basedOnClassOrViaCustomSetImageBlock:setImageBlock cacheType:SDImageCacheTypeNone imageURL:url];
        });
    }

    id<SDWebImageOperation> operation = nil;

    // url非空，进入正常逻辑处理，为空停止旋转菊花，并触发空图片错误回调
    if (url) {
        // 获取`UIImageView+WebCache`中的sd_imageProgress关联属性，并将进度重置
        NSProgress *imageProgress = objc_getAssociatedObject(self, @selector(sd_imageProgress));
        if (imageProgress) {
            imageProgress.totalUnitCount = 0;
            imageProgress.completedUnitCount = 0;
        }

#if SD_UIKIT || SD_MAC
        // 如果设置了菊花（指示器），开始旋转菊花（默认是无菊花，未调用setSd_imageIndicator）
        [self sd_startImageIndicator];
        id<SDWebImageIndicator> imageIndicator = self.sd_imageIndicator;
#endif
        // 设置图片加载进度回调
        // 🔅 receivedSize：已获取的图片大小，expectedSize：期望的图片总大小
        SDImageLoaderProgressBlock combinedProgressBlock = ^(NSInteger receivedSize, NSInteger expectedSize, NSURL *_Nullable targetURL) {
            // imageProgress关联属性非空，设置相应的参数
          if (imageProgress) {
              imageProgress.totalUnitCount = expectedSize;
              imageProgress.completedUnitCount = receivedSize;
          }
#if SD_UIKIT || SD_MAC
            // 如果菊花实现了`SDWebImageIndicator`协议中的updateIndicatorProgress方法，就更新进度
          if ([imageIndicator respondsToSelector:@selector(updateIndicatorProgress:)]) {
              // 获取图片完成的进度
              double progress = 0;
              if (expectedSize != 0) {
                  progress = (double)receivedSize / expectedSize;
              }
              // 进度是在0-1之前，
              // ⚠️ 异常情况下<0,取0，>1,取1
              progress = MAX(MIN(progress, 1), 0); // 0.0 - 1.0
              // 主线程更新菊花
              dispatch_async(dispatch_get_main_queue(), ^{
                [imageIndicator updateIndicatorProgress:progress];
              });
          }
#endif
            // 图片进度回调
          if (progressBlock) {
              progressBlock(receivedSize, expectedSize, targetURL);
          }
        };
        //【step 3】: 获取图片加载operation
        @weakify(self);
        operation = [manager loadImageWithURL:url
                                      options:options
                                      context:context
                                     progress:combinedProgressBlock
                                    completed:^(UIImage *image, NSData *data, NSError *error, SDImageCacheType cacheType, BOOL finished, NSURL *imageURL) {
                                      @strongify(self);
                                      if (!self) {
                                          return;
                                      }
                                      // 异常状态下，在完成回调中将进度设置为100%
                                      // if the progress not been updated, mark it to complete state
                                      if (imageProgress && finished && !error && imageProgress.totalUnitCount == 0 && imageProgress.completedUnitCount == 0) {
                                          imageProgress.totalUnitCount = SDWebImageProgressUnitCountUnknown;
                                          imageProgress.completedUnitCount = SDWebImageProgressUnitCountUnknown;
                                      }

#if SD_UIKIT || SD_MAC
                                      // 回调完成，停止菊花
                                      // check and stop image indicator
                                      if (finished) {
                                          [self sd_stopImageIndicator];
                                      }
#endif
                                      // finished = true,或 SDWebImageAvoidAutoSetImage（禁止自动设置图片）
                                      BOOL shouldCallCompletedBlock = finished || (options & SDWebImageAvoidAutoSetImage);
                                      // 图片存在且SDWebImageAvoidAutoSetImage，或者图片不存在且未设置SDWebImageDelayPlaceholder
                                      BOOL shouldNotSetImage = ((image && (options & SDWebImageAvoidAutoSetImage)) ||
                                                                (!image && !(options & SDWebImageDelayPlaceholder)));
                                      SDWebImageNoParamsBlock callCompletedBlockClosure = ^{
                                        if (!self) {
                                            return;
                                        }
                                        if (!shouldNotSetImage) {
                                            [self sd_setNeedsLayout];
                                        }
                                        // 已完成且回调存在
                                        if (completedBlock && shouldCallCompletedBlock) {
                                            completedBlock(image, data, error, cacheType, finished, url);
                                        }
                                      };

                                      // case 1a: we got an image, but the SDWebImageAvoidAutoSetImage flag is set
                                      // OR
                                      // case 1b: we got no image and the SDWebImageDelayPlaceholder is not set
                                      if (shouldNotSetImage) {
                                          dispatch_main_async_safe(callCompletedBlockClosure);
                                          return;
                                      }

                                      UIImage *targetImage = nil;
                                      NSData *targetData = nil;
                                      if (image) {
                                          // 获取了图片且未设置`SDWebImageAvoidAutoSetImage`
                                          // case 2a: we got an image and the SDWebImageAvoidAutoSetImage is not set
                                          targetImage = image;
                                          targetData = data;
                                      }
                                      else if (options & SDWebImageDelayPlaceholder) {
                                          // 未获取到图片且设置了`SDWebImageDelayPlaceholder`，用占位图当返回结果
                                          // ⚠️ 这里是`SDWebImageDelayPlaceholder`定义所描述的情形
                                          // case 2b: we got no image and the SDWebImageDelayPlaceholder flag is set
                                          targetImage = placeholder;
                                          targetData = nil;
                                      }

#if SD_UIKIT || SD_MAC
                                      // 判断是否需要转场动画
                                      // check whether we should use the image transition
                                      SDWebImageTransition *transition = nil;
                                      BOOL shouldUseTransition = NO;
                                      if (options & SDWebImageForceTransition) {
                                          // 设置强制转场SDWebImageForceTransition
                                          // Always
                                          shouldUseTransition = YES;
                                      }
                                      else if (cacheType == SDImageCacheTypeNone) {
                                          // 从网络中获取也需要转场
                                          // From network
                                          shouldUseTransition = YES;
                                      }
                                      else {
                                          // 从内存获取不需要转场，
                                          // 如果从磁盘中获取且设置SDWebImageQueryMemoryDataSync或SDWebImageQueryDiskDataSync 不需要转场
                                          // From disk (and, user don't use sync query)
                                          if (cacheType == SDImageCacheTypeMemory) {
                                              shouldUseTransition = NO;
                                          }
                                          else if (cacheType == SDImageCacheTypeDisk) {
                                              if (options & SDWebImageQueryMemoryDataSync || options & SDWebImageQueryDiskDataSync) {
                                                  shouldUseTransition = NO;
                                              }
                                              else {
                                                  shouldUseTransition = YES;
                                              }
                                          }
                                          else {
                                              // Not valid cache type, fallback
                                              shouldUseTransition = NO;
                                          }
                                      }
                                      // 处理转场回调
                                      if (finished && shouldUseTransition) {
                                          transition = self.sd_imageTransition;
                                      }
#endif
                                      // 🍉 回到主线程并将图片设置相应的视图上
                                      dispatch_main_async_safe(^{
#if SD_UIKIT || SD_MAC
                                        [self sd_setImage:targetImage
                                                                       imageData:targetData
                                            basedOnClassOrViaCustomSetImageBlock:setImageBlock
                                                                      transition:transition
                                                                       cacheType:cacheType
                                                                        imageURL:imageURL];
#else
                [self sd_setImage:targetImage
                                               imageData:targetData
                    basedOnClassOrViaCustomSetImageBlock:setImageBlock
                                               cacheType:cacheType
                                                imageURL:imageURL];
#endif
                                        callCompletedBlockClosure();
                                      });
            
                                    }];
        // 🍉 将operation 保存到sd_operationDictionary内
        [self sd_setImageLoadOperation:operation forKey:validOperationKey];
    }
    else {
#if SD_UIKIT || SD_MAC
        [self sd_stopImageIndicator];
#endif
        if (completedBlock) {
            dispatch_main_async_safe(^{
              NSError *error = [NSError errorWithDomain:SDWebImageErrorDomain code:SDWebImageErrorInvalidURL userInfo:@{ NSLocalizedDescriptionKey : @"Image url is nil" }];
              completedBlock(nil, nil, error, SDImageCacheTypeNone, YES, url);
            });
        }
    }

    return operation;
}
```

#### 关于sd_cancelImageLoadOperationWithKey

该方法主要用于取消指定key对应的operation任务，相关代码发如下：

```
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
```

#### 关于sd_operationDictionary

它是`WebCacheOperation`分类中的一个关联属性，用[NSMapTable](https://nshipster.cn/nshashtable-and-nsmaptable/)来实现,代码如下

```
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
```

NSMapTable 是 NSDictionary 的通用版本。和 NSDictionary / NSMutableDictionary 不同的是，NSMapTable 具有下面这些特性：

* NSDictionary / NSMutableDictionary 对键进行拷贝，对值持有强引用。
* NSMapTable 是可变的，没有不可变的对应版本。
* NSMapTable 可以持有键和值的弱引用，当键或者值当中的一个被释放时，整个这一项就会被移除掉。
* NSMapTable 可以在加入成员时进行 copy 操作。
* NSMapTable 可以存储任意的指针，通过指针来进行相等性和散列检查。

**注意：** NSMapTable 专注于强引用和弱引用，意味着 Swift 中流行的值类型是不适用的，只能用于引用类型。

#### 关于sd_setImageLoadOperation

```
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
```

#### 关于sd_setImage:mageData:basedOnClassOrViaCustomSetImageBlock:transition:cacheType:imageURL:

该方法主要是将图片显示到视图上，并处理转场动画，部分代码如下：

```

- (void)sd_setImage:(UIImage *)image imageData:(NSData *)imageData basedOnClassOrViaCustomSetImageBlock:(SDSetImageBlock)setImageBlock transition:(SDWebImageTransition *)transition cacheType:(SDImageCacheType)cacheType imageURL:(NSURL *)imageURL
{
    UIView *view = self;
    SDSetImageBlock finalSetImageBlock;
    // 正常情况下是不会设置setImageBlock回调，所以这里不会走，如果外部设置了，会走这里
    if (setImageBlock) {
        finalSetImageBlock = setImageBlock;
    }
    else if ([view isKindOfClass:[UIImageView class]]) {
        // 将图片设置到UIImageView上
        UIImageView *imageView = (UIImageView *)view;
        finalSetImageBlock = ^(UIImage *setImage, NSData *setImageData, SDImageCacheType setCacheType, NSURL *setImageURL) {
          imageView.image = setImage;
        };
    }
#if SD_UIKIT
    else if ([view isKindOfClass:[UIButton class]]) {
        // 将图片设置到UIButton上
        UIButton *button = (UIButton *)view;
        finalSetImageBlock = ^(UIImage *setImage, NSData *setImageData, SDImageCacheType setCacheType, NSURL *setImageURL) {
          [button setImage:setImage forState:UIControlStateNormal];
        };
    }
#endif
#if SD_MAC
    else if ([view isKindOfClass:[NSButton class]]) {
        NSButton *button = (NSButton *)view;
        finalSetImageBlock = ^(UIImage *setImage, NSData *setImageData, SDImageCacheType setCacheType, NSURL *setImageURL) {
          button.image = setImage;
        };
    }
#endif
#if SD_MAC
    else if ([view isKindOfClass:[NSButton class]]) {
        NSButton *button = (NSButton *)view;
        finalSetImageBlock = ^(UIImage *setImage, NSData *setImageData, SDImageCacheType setCacheType, NSURL *setImageURL) {
          button.image = setImage;
        };
    }
    // 转场动画 
    if (transition) {
        ////
        省略
        ////
    }
}

```

## 【step 3】loadimage(url, options, context, progressBiock, completedBlock)

该方法位于`SDWebImageManager`内，主要是做一些验证的操作，其主要加载图片的逻辑由`callCacheProcessForOperation`承担

```
- (SDWebImageCombinedOperation *)loadImageWithURL:(nullable NSURL *)url
                                          options:(SDWebImageOptions)options
                                          context:(nullable SDWebImageContext *)context
                                         progress:(nullable SDImageLoaderProgressBlock)progressBlock
                                        completed:(nonnull SDInternalCompletionBlock)completedBlock
{
    // Invoking this method without a completedBlock is pointless
    NSAssert(completedBlock != nil, @"If you mean to prefetch the image, use -[SDWebImagePrefetcher prefetchURLs] instead");

    // Very common mistake is to send the URL using NSString object instead of NSURL. For some strange reason, Xcode won't
    // throw any warning for this type mismatch. Here we failsafe this error by allowing URLs to be passed as NSString.
    // 如果外部传入NSString，这里尝试转换成NSURL
    if ([url isKindOfClass:NSString.class]) {
        url = [NSURL URLWithString:(NSString *)url];
    }

    // Prevents app crashing on argument type error like sending NSNull instead of NSURL
    // 判断url是否合法
    if (![url isKindOfClass:NSURL.class]) {
        url = nil;
    }

    SDWebImageCombinedOperation *operation = [SDWebImageCombinedOperation new];
    operation.manager = self;

    BOOL isFailedUrl = NO;
    if (url) {
        // 判断url是否加载失败过
        SD_LOCK(_failedURLsLock);
        isFailedUrl = [self.failedURLs containsObject:url];
        SD_UNLOCK(_failedURLsLock);
    }

    // Preprocess the options and context arg to decide the final the result for manager
    SDWebImageOptionsResult *result = [self processedResultForURL:url options:options context:context];

    // url为长度为空或失败过且未设置重试（SDWebImageRetryFailed）
    if (url.absoluteString.length == 0 || (!(options & SDWebImageRetryFailed) && isFailedUrl)) {
        NSString *description = isFailedUrl ? @"Image url is blacklisted" : @"Image url is nil";
        NSInteger code = isFailedUrl ? SDWebImageErrorBlackListed : SDWebImageErrorInvalidURL;
        // 触发错误完成回调，内包含错误信息，这里的错误信息要么是图片加载失败要么是url为空
        [self callCompletionBlockForOperation:operation completion:completedBlock error:[NSError errorWithDomain:SDWebImageErrorDomain code:code userInfo:@{NSLocalizedDescriptionKey : description}] queue:result.context[SDWebImageContextCallbackQueue] url:url];
        return operation;
    }

    // 如果之前未加载过，将operation加到runningOperations中
    SD_LOCK(_runningOperationsLock);
    [self.runningOperations addObject:operation];
    SD_UNLOCK(_runningOperationsLock);

    // Start the entry to load image from cache, the longest steps are below
    // Steps without transformer:
    // 1. query image from cache, miss
    // 2. download data and image
    // 3. store image to cache

    // Steps with transformer:
    // 1. query transformed image from cache, miss
    // 2. query original image from cache, miss
    // 3. download data and image
    // 4. do transform in CPU
    // 5. store original image to cache
    // 6. store transformed image to cache
    // 🍉查询缓存操作
    [self callCacheProcessForOperation:operation url:url options:result.options context:result.context progress:progressBlock completed:completedBlock];

    return operation;
}
```

#### `callCacheProcessForOperation` 真正的加载图片的入口，具体代码如下：

```
// Query normal cache process
- (void)callCacheProcessForOperation:(nonnull SDWebImageCombinedOperation *)operation
                                 url:(nonnull NSURL *)url
                             options:(SDWebImageOptions)options
                             context:(nullable SDWebImageContext *)context
                            progress:(nullable SDImageLoaderProgressBlock)progressBlock
                           completed:(nullable SDInternalCompletionBlock)completedBlock
{
    // Grab the image cache to use
    // 如果context外部未传入相应的SDImageCache,默认用imageCache (SDImageCache单例)
    id<SDImageCache> imageCache = context[SDWebImageContextImageCache];
    if (!imageCache) {
        imageCache = self.imageCache;
    }
    // Get the query cache type
    // 默认是缓存类型是SDImageCacheTypeAll，如果通过context传入，则用外部的
    SDImageCacheType queryCacheType = SDImageCacheTypeAll;
    if (context[SDWebImageContextQueryCacheType]) {
        queryCacheType = [context[SDWebImageContextQueryCacheType] integerValue];
    }

    // Check whether we should query cache
    // 如果未设置SDWebImageFromLoaderOnly（直接网络加载）那么就先查找缓存，否则直接网络加载
    BOOL shouldQueryCache = !SD_OPTIONS_CONTAINS(options, SDWebImageFromLoaderOnly);
    if (shouldQueryCache) {
        // transformed cache key
        // 根据url生成相应的key
        NSString *key = [self cacheKeyForURL:url context:context];
        @weakify(operation);
        // 【step 4】查找图片
        operation.cacheOperation = [imageCache queryImageForKey:key
                                                        options:options
                                                        context:context
                                                      cacheType:queryCacheType
                                                     completion:^(UIImage *_Nullable cachedImage, NSData *_Nullable cachedData, SDImageCacheType cacheType) {
                                                       @strongify(operation);
                                                       // operation不存在或取消，触发错误完成回调
                                                       if (!operation || operation.isCancelled) {
                                                           // Image combined operation cancelled by user
                                                           [self callCompletionBlockForOperation:operation completion:completedBlock error:[NSError errorWithDomain:SDWebImageErrorDomain code:SDWebImageErrorCancelled userInfo:@{ NSLocalizedDescriptionKey : @"Operation cancelled by user during querying the cache" }] queue:context[SDWebImageContextCallbackQueue] url:url];
                                                           [self safelyRemoveOperationFromRunning:operation];
                                                           return;
                                                       }
                                                       else if (!cachedImage) {
                                                           // 如果缓存图片不存在，将当前传入的key和根据urla获取的key比较，如果相符，那么直接查找原始缓存好的图片，否则重新下载图片
                                                           NSString *originKey = [self originalCacheKeyForURL:url context:context];
                                                           BOOL mayInOriginalCache = ![key isEqualToString:originKey];
                                                           // Have a chance to query original cache instead of downloading, then applying transform
                                                           // Thumbnail decoding is done inside SDImageCache's decoding part, which does not need post processing for transform
                                                           if (mayInOriginalCache) {
                                                               [self callOriginalCacheProcessForOperation:operation url:url options:options context:context progress:progressBlock completed:completedBlock];
                                                               return;
                                                           }
                                                       }
                                                       // Continue download process
                                                       // 🍉 直接下载图片
                                                       [self callDownloadProcessForOperation:operation url:url options:options context:context cachedImage:cachedImage cachedData:cachedData cacheType:cacheType progress:progressBlock completed:completedBlock];
                                                     }];
    }
    else {
        // Continue download process
        // 🍉 直接下载图片
        [self callDownloadProcessForOperation:operation url:url options:options context:context cachedImage:nil cachedData:nil cacheType:SDImageCacheTypeNone progress:progressBlock completed:completedBlock];
    }
}
```

## 【step 4】queryImage(key, options, completionBlock)

查询图片的方法位于`SDImageCache`文件内，是一个分类，主要用于查询图片之前的配置操作，具体的查询操作由`queryCacheOperationForKey`来完成。具体代码如下：

```
- (id<SDWebImageOperation>)queryImageForKey:(NSString *)key options:(SDWebImageOptions)options context:(nullable SDWebImageContext *)context cacheType:(SDImageCacheType)cacheType completion:(nullable SDImageCacheQueryCompletionBlock)completionBlock
{
    // 获取缓存相关的配置
    SDImageCacheOptions cacheOptions = 0;
    if (options & SDWebImageQueryMemoryData)
        cacheOptions |= SDImageCacheQueryMemoryData;
    if (options & SDWebImageQueryMemoryDataSync)
        cacheOptions |= SDImageCacheQueryMemoryDataSync;
    if (options & SDWebImageQueryDiskDataSync)
        cacheOptions |= SDImageCacheQueryDiskDataSync;
    if (options & SDWebImageScaleDownLargeImages)
        cacheOptions |= SDImageCacheScaleDownLargeImages;
    if (options & SDWebImageAvoidDecodeImage)
        cacheOptions |= SDImageCacheAvoidDecodeImage;
    if (options & SDWebImageDecodeFirstFrameOnly)
        cacheOptions |= SDImageCacheDecodeFirstFrameOnly;
    if (options & SDWebImagePreloadAllFrames)
        cacheOptions |= SDImageCachePreloadAllFrames;
    if (options & SDWebImageMatchAnimatedImageClass)
        cacheOptions |= SDImageCacheMatchAnimatedImageClass;

    return [self queryCacheOperationForKey:key options:cacheOptions context:context cacheType:cacheType done:completionBlock];
}
```

##### `queryCacheOperationForKey`源码如下所示：

```
- (nullable SDImageCacheToken *)queryCacheOperationForKey:(nullable NSString *)key options:(SDImageCacheOptions)options context:(nullable SDWebImageContext *)context cacheType:(SDImageCacheType)queryCacheType done:(nullable SDImageCacheQueryCompletionBlock)doneBlock
{
    // 处理key为nil的情况
    if (!key) {
        if (doneBlock) {
            doneBlock(nil, nil, SDImageCacheTypeNone);
        }
        return nil;
    }
    // 处理无效缓存类型的情况
    // Invalid cache type
    if (queryCacheType == SDImageCacheTypeNone) {
        if (doneBlock) {
            doneBlock(nil, nil, SDImageCacheTypeNone);
        }
        return nil;
    }

    // First check the in-memory cache...
    // 1、首先查找内存缓存
    UIImage *image;
    if (queryCacheType != SDImageCacheTypeDisk) {
        image = [self imageFromMemoryCacheForKey:key];
    }
    
    // 内存中存在相应的图片
    if (image) {
        // 是否只解码第一帧
        if (options & SDImageCacheDecodeFirstFrameOnly) {
            // Ensure static image
            // 如果image是动图，那么只获取其第一帧
            if (image.sd_isAnimated) {
#if SD_MAC
                image = [[NSImage alloc] initWithCGImage:image.CGImage scale:image.scale orientation:kCGImagePropertyOrientationUp];
#else
                image = [[UIImage alloc] initWithCGImage:image.CGImage scale:image.scale orientation:image.imageOrientation];
#endif
            }
        }
        else if (options & SDImageCacheMatchAnimatedImageClass) {
            // Check image class matching
            // 如果设置了图片期望的类型，但是 image 的类与设置的类型不一致则将 image 置空
            Class animatedImageClass = image.class;
            Class desiredImageClass = context[SDWebImageContextAnimatedImageClass];
            if (desiredImageClass && ![animatedImageClass isSubclassOfClass:desiredImageClass]) {
                image = nil;
            }
        }
    }

    // 是否设置了只查询内存
    // 缓存类型是SDImageCacheTypeMemory 或在图片存在的情况下，未设置SDImageCacheQueryMemoryData（强制查询图片数据）
    BOOL shouldQueryMemoryOnly = (queryCacheType == SDImageCacheTypeMemory) || (image && !(options & SDImageCacheQueryMemoryData));
    // 只查询内存的情况下，直接走完成回调
    if (shouldQueryMemoryOnly) {
        if (doneBlock) {
            doneBlock(image, nil, SDImageCacheTypeMemory);
        }
        return nil;
    }

    // 2、查找磁盘缓存
    // Second check the disk cache...
    // queue是否经context由外部传入，这里可空
    SDCallbackQueue *queue = context[SDWebImageContextCallbackQueue];
    SDImageCacheToken *operation = [[SDImageCacheToken alloc] initWithDoneBlock:doneBlock];
    operation.key = key;
    operation.callbackQueue = queue;
    
    // 判断是否需要同步查找磁盘缓存
    // 1. 内存缓存命中且 SDImageCacheQueryMemoryDataSync
    // 2. 内存缓存未命中且 SDImageCacheQueryDiskDataSync
    BOOL shouldQueryDiskSync = ((image && options & SDImageCacheQueryMemoryDataSync) ||
                                (!image && options & SDImageCacheQueryDiskDataSync));
    // 查询磁盘数据回调,下同，只不过这里返回NSData, 下面返回UIImage
    NSData * (^queryDiskDataBlock)(void) = ^NSData *
    {
        @synchronized(operation)
        {
            if (operation.isCancelled) {
                return nil;
            }
        }

        return [self diskImageDataBySearchingAllPathsForKey:key];
    };
    // 查询磁盘图片回调
    UIImage * (^queryDiskImageBlock)(NSData *) = ^UIImage *(NSData *diskData)
    {
        // 判断操作是否被取消
        @synchronized(operation)
        {
            if (operation.isCancelled) {
                return nil;
            }
        }

        UIImage *diskImage;
        if (image) {
            // the image is from in-memory cache, but need image data
            // 这里的图片是从内存中获取的
            diskImage = image;
        }
        else if (diskData) {
            // 从磁盘中获取的图片默认要缓存到内存中
            BOOL shouldCacheToMomery = YES;
            // 取出context中的缓存类型
            if (context[SDWebImageContextStoreCacheType]) {
                SDImageCacheType cacheType = [context[SDWebImageContextStoreCacheType] integerValue];
                shouldCacheToMomery = (cacheType == SDImageCacheTypeAll || cacheType == SDImageCacheTypeMemory);
            }
            CGSize thumbnailSize = CGSizeZero;
            // 取出context中的缩略图大小，正常情况下是未传入的这里可为空
            NSValue *thumbnailSizeValue = context[SDWebImageContextImageThumbnailPixelSize];
            if (thumbnailSizeValue != nil) {
#if SD_MAC
                thumbnailSize = thumbnailSizeValue.sizeValue;
#else
                thumbnailSize = thumbnailSizeValue.CGSizeValue;
#endif
            }
            // ⁉️:缩略图不应该回到内存中，也就是不应该放在memoryCache里（这里的判断有点不太懂）
            if (thumbnailSize.width > 0 && thumbnailSize.height > 0) {
                // Query full size cache key which generate a thumbnail, should not write back to full size memory cache
                shouldCacheToMomery = NO;
            }
            // Special case: If user query image in list for the same URL, to avoid decode and write **same** image object into disk cache multiple times, we query and check memory cache here again.
            // 再次查询内存中是否存在
            if (shouldCacheToMomery && self.config.shouldCacheImagesInMemory) {
                diskImage = [self.memoryCache objectForKey:key];
            }
            // decode image data only if in-memory cache missed
            // 如果内存中不存在图片，就利用diskData生成
            if (!diskImage) {
                diskImage = [self diskImageForKey:key data:diskData options:options context:context];
                // 设置了内存缓存 将图片放入内存中
                if (shouldCacheToMomery && diskImage && self.config.shouldCacheImagesInMemory) {
                    NSUInteger cost = diskImage.sd_memoryCost;
                    [self.memoryCache setObject:diskImage forKey:key cost:cost];
                }
            }
        }
        return diskImage;
    };

    // Query in ioQueue to keep IO-safe
    // 同步查询
    if (shouldQueryDiskSync) {
        __block NSData *diskData;
        __block UIImage *diskImage;
        dispatch_sync(self.ioQueue, ^{
          diskData = queryDiskDataBlock();
          diskImage = queryDiskImageBlock(diskData);
        });
        // 获取上步的data和image，放入doneBlock回调中
        if (doneBlock) {
            doneBlock(diskImage, diskData, SDImageCacheTypeDisk);
        }
    }
    else {
        // 异步查询
        dispatch_async(self.ioQueue, ^{
          NSData *diskData = queryDiskDataBlock();
          UIImage *diskImage = queryDiskImageBlock(diskData);
          @synchronized(operation)
          {
              if (operation.isCancelled) {
                  return;
              }
          }
          if (doneBlock) {
              // queue 为外部传入，未传入的情况下用主队列
              [(queue ?: SDCallbackQueue.mainQueue) async:^{
                // Dispatch from IO queue to main queue need time, user may call cancel during the dispatch timing
                // This check is here to avoid double callback (one is from `SDImageCacheToken` in sync)
                // 防止再次回调
                @synchronized(operation)
                {
                    if (operation.isCancelled) {
                        return;
                    }
                }
                doneBlock(diskImage, diskData, SDImageCacheTypeDisk);
              }];
          }
        });
    }

    return operation;
}

```

## 【step 5】disk result

## 【step 6】requestImageWithURL(url, options, context, progressBlock, completedBlock)

## 【step 7】network result

## 【step 8】store(image, imageData, key, toDisk completionBlock)

## 【step 9】Image

## 【step 10】set image


