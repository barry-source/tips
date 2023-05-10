# 优化：

## 一、[启动优化](https://www.jianshu.com/p/b19cd03eea68)

涉及main函数之前执行了什么，才能谈优化，pre-main()执行的过程大致如下：
* 内核先加载帮助程序dyld
* dyld递归加载依赖的动态链接库dylib
* 修正所有在DATA页的指针指向
* 运行所有的初始化initializers

### dyld执行操作

* 递归加载依赖的动态链接库dylib
* Rebase 和bind
* ObjC
* initializers

### 启动优化的操作

* 移除不需要用到的动态库
* 移除不需要用到的类
* 合并功能类似的类和扩展
* 尽量避免在+load方法里执行的操作，可以推迟到+initialize方法中。
* 使用swift

## 二、卡顿优化
[像素如何显示到屏幕上](https://www.objc.io/issues/3-views/moving-pixels-onto-the-screen/)

#### 卡顿原因的产生:

    按照60FPS的刷帧率，每隔16ms就会有一次VSync信号,CPU和GPU处理的任务需要在这个时间内处理完，否则就会出现卡顿的现象

#### 卡顿优化:(CPU)

* 尽量用轻量级的对象，比如用不到事件处理的地方，可以考虑使用CALayer取代UIView
* 不要频繁地修改UIView的相关属性，比如frame、bounds、transform等
* 尽量提前计算好布局，在有需要时一次性调整对应的属性，不要多次修改属性
* Autolayout会比直接设置frame消耗更多的CPU资源
* 图片的size最好刚好跟UIImageView的size保持一致
* 控制一下线程的最大并发数量
* 尽量把耗时的操作放到子线程 文本处理（尺寸计算、绘制） 图片处理（解码、绘制）

#### 卡顿优化:(GPU)

* 尽量避免短时间内大量图片的显示，尽可能将多张图片合成一张进行显示
* GPU能处理的最大纹理尺寸是4096x4096，一旦超过这个尺寸，就会占用CPU资源进行处理，所以纹理尽量不要超过这个尺寸
* 尽量减少视图数量和层次
* 减少透明的视图（alpha<1），不透明的就设置opaque为YES
* 尽量避免出现离屏渲染

## 离屏渲染
iOS中，渲染通常分为CPU和GPU渲染两种，而GPU渲染又分为在GPU缓冲区和非GPU缓冲区两种

- CPU渲染（软件渲染）,CPU绘制成bitmap，交给GPU
- GPU渲染（硬件渲染） 
    - GPU缓冲区渲染
    - 非GPU缓冲区渲染（额外开辟缓冲区）
    
通常，CPU渲染，和GPU非帧缓冲区内渲染统称为离屏渲染。
因为，CPU和帧缓冲区是为图形图像显示做了高度优化的，速度较快。

什么情况下会触发离屏幕渲染？

1. 为图层设置遮罩（layer.mask）。
2. 将图层的layer.masksToBounds && view.clipsToBounds属性设置为true。
3. 将图层layer.allowsGroupOpacity属性设置为YES和layer.opacity小于1.0。
4. 为图层设置阴影（layer.shadow *。
5. 为图层设置layer.shouldRasterize=true。
6. 具有layer.cornerRadius，layer.edgeAntialiasingMask，layer.allowsEdgeAntialiasing的图层。
7. 文本（任何种类，包括UILabel，CATextLayer，Core Text等。
8. 使用CGContext在drawRect :方法中绘制大部分情况下会导致离屏渲染，甚至仅仅是一个空的实现。

上文提到了，CoreGraphics通常是CPU渲染成bitmap交给GPU，假如频繁的大量的绘制出现，往往会导致界面卡顿。而CALayer是对GPU做过优化的，能够硬件加速。所以，对于性能要求较高的绘制，尝试用CALayer替代CoreGraphics

## tableview性能优化

1、使用cell重用机制
2、分页加载数据，达到一定阀值再去加载下页数据
3、缓存cell高度
4、避免cell的重新布局，比如cell的添加和移动操作尽量换成hidden操作
5、尽可能使用局部更新，例如reloadSection
6、尽量减少cell中控件的数量
7、将cell及其子视图的opaque属性设为YES（默认值UIButton内部的label的opaque默认值都是NO]）。采用无aplha通道的图片，Cell中尽量少使用clearColor，无背景色，透明度也不要设置为0。
8、耗时任务放到子线程中，比如图片下载
9、图片异步下载，异步解码，缓存解码结果，常用的三方库框架会做解码的操作
10、圆角的处理，尽量避免直接使用maskToBound, clipsToBound, 这样会造成离屏渲染
11、阿里云图片裁剪

## instrument调试
### 1、Time Profiler
用来检测CPU性能、各个方法执行的时间


### 2、Core Animation

用于调试离屏渲染，绘图，动画，图层混合等GPU耗时操作

- Color Blended Layers： 这个选项基于渲染程度对屏幕中的混合区域进行绿到红的高亮显示，越红表示性能越差，会对帧率等指标造成较大的影响。红色通常是由于多个半透明图层叠加引起。
- Color Hits Green and Misses Red：当 UIView.layer.shouldRasterize = YES时，耗时的图片绘制会被缓存，并当做一个简单的扁平图片来呈现。这时候，如果页面的其他区块(比如 UITableViewCell 的复用)使用缓存直接命中，就显示绿色，反之不命中，就显示红色。红色越多，性能越差。因为栅格化生成缓存的过程是有开销的，如果缓存能被大量命中和有效使用，则总体上会降低开销，反之则意味着要频繁生成新的缓存，这会让性能问题雪上加霜。
- Color Copied Images： 对于GPU 不支持的色彩格式的图片只能由 CPU来处理，把这样的图片标为蓝色。蓝色越多，性能越差。因为，我们不希望在滚动视图的时候，由 CPU 来处理图片，这样可能会对主线程造成阻塞。
- Color Misaligned Images： 这个选项检查了图片是否被缩放，以及像素是否对齐。图片被放缩的会被标记为黄色，像素不对齐则会标注为紫色。黄色、紫色越多，性能越差。
- Color Offscreen-Rendered Yellow：这个选项会把那些离屏渲染的图层显示为黄色。黄色越多，性能越差。这些显示为黄色的图层很可能需要用 shadowPath或者 shouldRasterize来优化。

### 3、Leaks
用来检测内存泄露


## 2、耗电优化

## 3、网络优化