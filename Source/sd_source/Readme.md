
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

注意点：

- SDWebImageContext：这个类型是在5.0之后出现的，本质就是一个字典，如果外部未提供的话，内部会自动生成一个
- SDExternalCompletionBlock: 外部完成回调，相应的SDWebImage内部使用的是SDInternalCompletionBlock，两种回调的定义如下

    ```
    typedef void(^SDExternalCompletionBlock)(UIImage * _Nullable image, NSError * _Nullable error, SDImageCacheType cacheType, NSURL * _Nullable imageURL);

typedef void(^SDInternalCompletionBlock)(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, SDImageCacheType cacheType, BOOL finished, NSURL * _Nullable imageURL);
    ```


## 【step 2】sd_internalSetImageWithURL

## 【step 3】loadimage(url, options, context, progressBiock, completedBlock)

## 【step 4】queryImage(key, options, completionBlock)

## 【step 5】disk result

## 【step 6】loadImage(url, options, context, progressBlock, completedBlock)

## 【step 7】network result

## 【step 8】store(image, imageData, key, toDisk completionBlock)

## 【step 9】Image

## 【step 10】set image



