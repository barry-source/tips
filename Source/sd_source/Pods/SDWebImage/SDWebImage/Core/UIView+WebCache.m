/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIView+WebCache.h"
#import "objc/runtime.h"
#import "UIView+WebCacheOperation.h"
#import "SDWebImageError.h"
#import "SDInternalMacros.h"
#import "SDWebImageTransitionInternal.h"
#import "SDImageCache.h"

const int64_t SDWebImageProgressUnitCountUnknown = 1LL;

@implementation UIView (WebCache)

- (nullable NSURL *)sd_imageURL
{
    return objc_getAssociatedObject(self, @selector(sd_imageURL));
}

- (void)setSd_imageURL:(NSURL *_Nullable)sd_imageURL
{
    objc_setAssociatedObject(self, @selector(sd_imageURL), sd_imageURL, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (nullable NSString *)sd_latestOperationKey
{
    return objc_getAssociatedObject(self, @selector(sd_latestOperationKey));
}

- (void)setSd_latestOperationKey:(NSString *_Nullable)sd_latestOperationKey
{
    objc_setAssociatedObject(self, @selector(sd_latestOperationKey), sd_latestOperationKey, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSProgress *)sd_imageProgress
{
    NSProgress *progress = objc_getAssociatedObject(self, @selector(sd_imageProgress));
    if (!progress) {
        progress = [[NSProgress alloc] initWithParent:nil userInfo:nil];
        self.sd_imageProgress = progress;
    }
    return progress;
}

- (void)setSd_imageProgress:(NSProgress *)sd_imageProgress
{
    objc_setAssociatedObject(self, @selector(sd_imageProgress), sd_imageProgress, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

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

    // 和validOperationKey类似，在外部未传入context时，第一次取出就是nil
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

- (void)sd_cancelCurrentImageLoad
{
    [self sd_cancelImageLoadOperationWithKey:self.sd_latestOperationKey];
    self.sd_latestOperationKey = nil;
}

- (void)sd_setImage:(UIImage *)image imageData:(NSData *)imageData basedOnClassOrViaCustomSetImageBlock:(SDSetImageBlock)setImageBlock cacheType:(SDImageCacheType)cacheType imageURL:(NSURL *)imageURL
{
#if SD_UIKIT || SD_MAC
    [self sd_setImage:image
                                   imageData:imageData
        basedOnClassOrViaCustomSetImageBlock:setImageBlock
                                  transition:nil
                                   cacheType:cacheType
                                    imageURL:imageURL];
#else
    // watchOS does not support view transition. Simplify the logic
    if (setImageBlock) {
        setImageBlock(image, imageData, cacheType, imageURL);
    }
    else if ([self isKindOfClass:[UIImageView class]]) {
        UIImageView *imageView = (UIImageView *)self;
        [imageView setImage:image];
    }
#endif
}

#if SD_UIKIT || SD_MAC
- (void)sd_setImage:(UIImage *)image imageData:(NSData *)imageData basedOnClassOrViaCustomSetImageBlock:(SDSetImageBlock)setImageBlock transition:(SDWebImageTransition *)transition cacheType:(SDImageCacheType)cacheType imageURL:(NSURL *)imageURL
{
    UIView *view = self;
    SDSetImageBlock finalSetImageBlock;
    if (setImageBlock) {
        finalSetImageBlock = setImageBlock;
    }
    else if ([view isKindOfClass:[UIImageView class]]) {
        UIImageView *imageView = (UIImageView *)view;
        finalSetImageBlock = ^(UIImage *setImage, NSData *setImageData, SDImageCacheType setCacheType, NSURL *setImageURL) {
          imageView.image = setImage;
        };
    }
#if SD_UIKIT
    else if ([view isKindOfClass:[UIButton class]]) {
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

    if (transition) {
        NSString *originalOperationKey = view.sd_latestOperationKey;

#if SD_UIKIT
        [UIView transitionWithView:view
            duration:0
            options:0
            animations:^{
              if (!view.sd_latestOperationKey || ![originalOperationKey isEqualToString:view.sd_latestOperationKey]) {
                  return;
              }
              // 0 duration to let UIKit render placeholder and prepares block
              if (transition.prepares) {
                  transition.prepares(view, image, imageData, cacheType, imageURL);
              }
            }
            completion:^(BOOL tempFinished) {
              [UIView transitionWithView:view
                  duration:transition.duration
                  options:transition.animationOptions
                  animations:^{
                    if (!view.sd_latestOperationKey || ![originalOperationKey isEqualToString:view.sd_latestOperationKey]) {
                        return;
                    }
                    if (finalSetImageBlock && !transition.avoidAutoSetImage) {
                        finalSetImageBlock(image, imageData, cacheType, imageURL);
                    }
                    if (transition.animations) {
                        transition.animations(view, image);
                    }
                  }
                  completion:^(BOOL finished) {
                    if (!view.sd_latestOperationKey || ![originalOperationKey isEqualToString:view.sd_latestOperationKey]) {
                        return;
                    }
                    if (transition.completion) {
                        transition.completion(finished);
                    }
                  }];
            }];
#elif SD_MAC
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *_Nonnull prepareContext) {
          if (!view.sd_latestOperationKey || ![originalOperationKey isEqualToString:view.sd_latestOperationKey]) {
              return;
          }
          // 0 duration to let AppKit render placeholder and prepares block
          prepareContext.duration = 0;
          if (transition.prepares) {
              transition.prepares(view, image, imageData, cacheType, imageURL);
          }
        }
            completionHandler:^{
              [NSAnimationContext runAnimationGroup:^(NSAnimationContext *_Nonnull context) {
                if (!view.sd_latestOperationKey || ![originalOperationKey isEqualToString:view.sd_latestOperationKey]) {
                    return;
                }
                context.duration = transition.duration;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                CAMediaTimingFunction *timingFunction = transition.timingFunction;
#pragma clang diagnostic pop
                if (!timingFunction) {
                    timingFunction = SDTimingFunctionFromAnimationOptions(transition.animationOptions);
                }
                context.timingFunction = timingFunction;
                context.allowsImplicitAnimation = SD_OPTIONS_CONTAINS(transition.animationOptions, SDWebImageAnimationOptionAllowsImplicitAnimation);
                if (finalSetImageBlock && !transition.avoidAutoSetImage) {
                    finalSetImageBlock(image, imageData, cacheType, imageURL);
                }
                CATransition *trans = SDTransitionFromAnimationOptions(transition.animationOptions);
                if (trans) {
                    [view.layer addAnimation:trans forKey:kCATransition];
                }
                if (transition.animations) {
                    transition.animations(view, image);
                }
              }
                  completionHandler:^{
                    if (!view.sd_latestOperationKey || ![originalOperationKey isEqualToString:view.sd_latestOperationKey]) {
                        return;
                    }
                    if (transition.completion) {
                        transition.completion(YES);
                    }
                  }];
            }];
#endif
    }
    else {
        if (finalSetImageBlock) {
            finalSetImageBlock(image, imageData, cacheType, imageURL);
        }
    }
}
#endif

- (void)sd_setNeedsLayout
{
#if SD_UIKIT
    [self setNeedsLayout];
#elif SD_MAC
    [self setNeedsLayout:YES];
#elif SD_WATCH
// Do nothing because WatchKit automatically layout the view after property change
#endif
}

#if SD_UIKIT || SD_MAC

#pragma mark - Image Transition
- (SDWebImageTransition *)sd_imageTransition
{
    return objc_getAssociatedObject(self, @selector(sd_imageTransition));
}

- (void)setSd_imageTransition:(SDWebImageTransition *)sd_imageTransition
{
    objc_setAssociatedObject(self, @selector(sd_imageTransition), sd_imageTransition, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Indicator
- (id<SDWebImageIndicator>)sd_imageIndicator
{
    return objc_getAssociatedObject(self, @selector(sd_imageIndicator));
}

- (void)setSd_imageIndicator:(id<SDWebImageIndicator>)sd_imageIndicator
{
    // Remove the old indicator view
    id<SDWebImageIndicator> previousIndicator = self.sd_imageIndicator;
    [previousIndicator.indicatorView removeFromSuperview];

    objc_setAssociatedObject(self, @selector(sd_imageIndicator), sd_imageIndicator, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    // Add the new indicator view
    UIView *view = sd_imageIndicator.indicatorView;
    if (CGRectEqualToRect(view.frame, CGRectZero)) {
        view.frame = self.bounds;
    }
// Center the indicator view
#if SD_MAC
    [view setFrameOrigin:CGPointMake(round((NSWidth(self.bounds) - NSWidth(view.frame)) / 2), round((NSHeight(self.bounds) - NSHeight(view.frame)) / 2))];
#else
    view.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
#endif
    view.hidden = NO;
    [self addSubview:view];
}

- (void)sd_startImageIndicator
{
    id<SDWebImageIndicator> imageIndicator = self.sd_imageIndicator;
    if (!imageIndicator) {
        return;
    }
    dispatch_main_async_safe(^{
      [imageIndicator startAnimatingIndicator];
    });
}

- (void)sd_stopImageIndicator
{
    id<SDWebImageIndicator> imageIndicator = self.sd_imageIndicator;
    if (!imageIndicator) {
        return;
    }
    dispatch_main_async_safe(^{
      [imageIndicator stopAnimatingIndicator];
    });
}

#endif

@end
