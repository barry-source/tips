
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
    if (context) {
        // copy to avoid mutable object
        context = [context copy];
    }
    else {
        context = [NSDictionary dictionary];
    }
    NSString *validOperationKey = context[SDWebImageContextSetImageOperationKey];
    if (!validOperationKey) {
        // pass through the operation key to downstream, which can used for tracing operation or image view class
        validOperationKey = NSStringFromClass([self class]);
        SDWebImageMutableContext *mutableContext = [context mutableCopy];
        mutableContext[SDWebImageContextSetImageOperationKey] = validOperationKey;
        context = [mutableContext copy];
    }
    self.sd_latestOperationKey = validOperationKey;
    [self sd_cancelImageLoadOperationWithKey:validOperationKey];
    self.sd_imageURL = url;

    SDWebImageManager *manager = context[SDWebImageContextCustomManager];
    if (!manager) {
        manager = [SDWebImageManager sharedManager];
    }
    else {
        // remove this manager to avoid retain cycle (manger -> loader -> operation -> context -> manager)
        SDWebImageMutableContext *mutableContext = [context mutableCopy];
        mutableContext[SDWebImageContextCustomManager] = nil;
        context = [mutableContext copy];
    }

    BOOL shouldUseWeakCache = NO;
    if ([manager.imageCache isKindOfClass:SDImageCache.class]) {
        shouldUseWeakCache = ((SDImageCache *)manager.imageCache).config.shouldUseWeakMemoryCache;
    }
    if (!(options & SDWebImageDelayPlaceholder)) {
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

    if (url) {
        // reset the progress
        NSProgress *imageProgress = objc_getAssociatedObject(self, @selector(sd_imageProgress));
        if (imageProgress) {
            imageProgress.totalUnitCount = 0;
            imageProgress.completedUnitCount = 0;
        }

#if SD_UIKIT || SD_MAC
        // check and start image indicator
        [self sd_startImageIndicator];
        id<SDWebImageIndicator> imageIndicator = self.sd_imageIndicator;
#endif

        SDImageLoaderProgressBlock combinedProgressBlock = ^(NSInteger receivedSize, NSInteger expectedSize, NSURL *_Nullable targetURL) {
          if (imageProgress) {
              imageProgress.totalUnitCount = expectedSize;
              imageProgress.completedUnitCount = receivedSize;
          }
#if SD_UIKIT || SD_MAC
          if ([imageIndicator respondsToSelector:@selector(updateIndicatorProgress:)]) {
              double progress = 0;
              if (expectedSize != 0) {
                  progress = (double)receivedSize / expectedSize;
              }
              progress = MAX(MIN(progress, 1), 0); // 0.0 - 1.0
              dispatch_async(dispatch_get_main_queue(), ^{
                [imageIndicator updateIndicatorProgress:progress];
              });
          }
#endif
          if (progressBlock) {
              progressBlock(receivedSize, expectedSize, targetURL);
          }
        };
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
                                      // if the progress not been updated, mark it to complete state
                                      if (imageProgress && finished && !error && imageProgress.totalUnitCount == 0 && imageProgress.completedUnitCount == 0) {
                                          imageProgress.totalUnitCount = SDWebImageProgressUnitCountUnknown;
                                          imageProgress.completedUnitCount = SDWebImageProgressUnitCountUnknown;
                                      }

#if SD_UIKIT || SD_MAC
                                      // check and stop image indicator
                                      if (finished) {
                                          [self sd_stopImageIndicator];
                                      }
#endif

                                      BOOL shouldCallCompletedBlock = finished || (options & SDWebImageAvoidAutoSetImage);
                                      BOOL shouldNotSetImage = ((image && (options & SDWebImageAvoidAutoSetImage)) ||
                                                                (!image && !(options & SDWebImageDelayPlaceholder)));
                                      SDWebImageNoParamsBlock callCompletedBlockClosure = ^{
                                        if (!self) {
                                            return;
                                        }
                                        if (!shouldNotSetImage) {
                                            [self sd_setNeedsLayout];
                                        }
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
                                          // case 2a: we got an image and the SDWebImageAvoidAutoSetImage is not set
                                          targetImage = image;
                                          targetData = data;
                                      }
                                      else if (options & SDWebImageDelayPlaceholder) {
                                          // case 2b: we got no image and the SDWebImageDelayPlaceholder flag is set
                                          targetImage = placeholder;
                                          targetData = nil;
                                      }

#if SD_UIKIT || SD_MAC
                                      // check whether we should use the image transition
                                      SDWebImageTransition *transition = nil;
                                      BOOL shouldUseTransition = NO;
                                      if (options & SDWebImageForceTransition) {
                                          // Always
                                          shouldUseTransition = YES;
                                      }
                                      else if (cacheType == SDImageCacheTypeNone) {
                                          // From network
                                          shouldUseTransition = YES;
                                      }
                                      else {
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
                                      if (finished && shouldUseTransition) {
                                          transition = self.sd_imageTransition;
                                      }
#endif
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

## 【step 3】loadimage(url, options, context, progressBiock, completedBlock)

## 【step 4】queryImage(key, options, completionBlock)

## 【step 5】disk result

## 【step 6】loadImage(url, options, context, progressBlock, completedBlock)

## 【step 7】network result

## 【step 8】store(image, imageData, key, toDisk completionBlock)

## 【step 9】Image

## 【step 10】set image


