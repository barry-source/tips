# 优化：
## tableview性能优化


1、使用cell重用机制
2、分页加载数据，达到一定阀值再去加载下页数据
3、对于不固定高度的cell，将计算之后的高度缓存下来，使用的时候直接获取
4、避免cell的重新布局，比如cell的添加和移动操作尽量换成hidden操作
5、使用局部更新，例如reloadSection
6、尽量减少cell中控件的数量
7、不透明的视图可以极大地提高渲染的速度。因此如非必要，可以将table cell及其子视图的opaque属性设为YES（默认值UIButton内部的label的opaque默认值都是NO]）。
Cell中不要使用clearColor，无背景色，透明度也不要设置为0。
8、耗时任务放到子线程中，比如图片下载
9、图片异步下载，异步解码，缓存解码结果，常用的三方库框架会做解码的操作
10、圆角的处理，尽量避免直接使用maskToBound, clipsToBound, 这样会造成离屏渲染
11、阿里云图片裁剪


## 离屏渲染
iOS中，渲染通常分为CPU和GPU渲染两种，而GPU渲染又分为在GPU缓冲区和非GPU缓冲区两种

- CPU渲染（软件渲染）,CPU绘制成bitmap，交给GPU
- GPU渲染（硬件渲染） 
    - GPU缓冲区渲染
    - 非GPU缓冲区渲染（额外开辟缓冲区）
    
通常，CPU渲染，和GPU非帧缓冲区内渲染统称为离屏渲染。
因为，CPU和帧缓冲区是为图形图像显示做了高度优化的，速度较快。

什么情况下会触发离屏幕渲染？

- 用CoreGraphics的CGContext绘制的
- 在drawRect中绘制的，即使drawRect是空的
- Layer具有Mask（比如圆角）或者Shadow
- Layer的隔栅化shouldRasterize为True
- 文本(UILabel,UITextfield,UITextView,CoreText,UITextLayer等)

上文提到了，CoreGraphics通常是CPU渲染成bitmap交给GPU，假如频繁的大量的绘制出现，往往会导致界面卡顿。而CALayer是对GPU做过优化的，能够硬件加速。所以，对于性能要求较高的绘制，尝试用CALayer替代CoreGraphics

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
