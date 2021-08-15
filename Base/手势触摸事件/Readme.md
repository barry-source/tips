
## 一、基本概念
在研究触摸事件之间先看下一些重要的类。
#### 1.1、UITouch
> An object representing the location, size, movement, and force of a touch occurring on the screen.
>`表示发生在屏幕上的可以表示触摸的位置，大小，移动和力度的一个对象`

通俗来讲就是一个手指触摸会生成一个UITouch对象，多个手指触摸会生成多个UITouch对象。

**UITouch的部分声明如下：**
```
@interface UITouch : NSObject
@property(nonatomic,readonly) NSTimeInterval      timestamp; //触摸的时间
@property(nonatomic,readonly) UITouchPhase        phase;     //触摸的阶段
@property(nonatomic,readonly) NSUInteger          tapCount;  //在一特定的时间内触摸某一个点的次数，可用来判断单击、双击、三击
@property(nonatomic,readonly) UITouchType         type;      //触摸的类型
@property(nonatomic,readonly) CGFloat             force;     //触摸力度，平均值是1.0
@property(nullable,nonatomic,readonly,strong) UIWindow     *window; //触摸发生时的window
@property(nullable,nonatomic,readonly,strong) UIView       *view; //发生触摸时的view，第一响应者
@end
```
每一个UITouch都会包含一个UITouchType(可以查看UITouch类定义，其内部有一个类型是UITouchType的属性type)，其类型定义如下
```
typedef NS_ENUM(NSInteger, UITouchType) {
    UITouchTypeDirect,                       // 直接触摸屏幕产生的touch
    UITouchTypeIndirect,                     // 非直接触摸屏幕产生的touch
    UITouchTypePencil NS_AVAILABLE_IOS(9_1), // 使用触摸笔产生的touch
    UITouchTypeStylus NS_AVAILABLE_IOS(9_1) = UITouchTypePencil, // 废弃, 使用触摸笔 选项
} NS_ENUM_AVAILABLE_IOS(9_0);
```

每一个UITouch都会包含一个UITouchPhase(可以查看UITouch类定义，其内部有一个类型是UITouchPhase的属性phase)，其类型定义如下

```
typedef NS_ENUM(NSInteger, UITouchPhase) {
    UITouchPhaseBegan,             // whenever a finger touches the surface.
    UITouchPhaseMoved,             // whenever a finger moves on the surface.
    UITouchPhaseStationary,        // whenever a finger is touching the surface but hasn't moved since the previous event.
    UITouchPhaseEnded,             // whenever a finger leaves the surface.
    UITouchPhaseCancelled,         // whenever a touch doesn't end but we need to stop tracking (e.g. putting device to face)
};
```
#### 1.2、UIEvent
> An object that describes a single user interaction with your app.
>`描述和app单次交互的对象。`

**UIEvent的部分声明如下：**
```
@interface UIEvent : NSObject
@property(nonatomic,readonly) UIEventType     type;  //事件的类型
@property(nonatomic,readonly) UIEventSubtype  subtype;  //事件的子类型
@property(nonatomic,readonly) NSTimeInterval  timestamp; //事件发生的时间
@property(nonatomic, readonly, nullable) NSSet <UITouch *> *allTouches; //每个事件中包含的触摸集合
@end
```
从上可以看出来每一个UIEvent事件可能包含多个UITouch，比如多指触摸。
每一个UIEvent都会包含一个UIEventType(可以查看UIEvent类定义，其内部有一个类型是UIEventType的属性type)，其类型定义如下
```
typedef NS_ENUM(NSInteger, UIEventType) {
    UIEventTypeTouches,        // 触摸事件，按钮、手势等
    UIEventTypeMotion,         // 运动事件，摇一摇、指南针等
    UIEventTypeRemoteControl,  //使用遥控器或耳机线控等产生的事件。如播放、暂停等。
    UIEventTypePresses NS_ENUM_AVAILABLE_IOS(9_0), // 3D touch
};
```

#### 1.3、UIResponder
> An abstract interface for responding to and handling events.
>`响应和处理事件的一个抽象接口。`

响应者对象(UIResponder的实例)构成app事件处理的基础。许多关键的对象都是UIResponder的实例，比如` UIApplication`， `UIWindow`,  `UIViewController`,以及所有的UIView.当前事件发生的时候，UIKit会自动将其派发到合适的对象来处理，这个对象就叫做`第一响应者`。

UIResponder中有很多的事件，其中包括处理触摸事件、点按事件、加速事件、远程控制事件。如果想响应事件，那么对应的UIResponder必须重写相应事件的方法，比如如果处理触摸事件，可以重写`touchesBegan`、`touchesMoved`、`touchesEnded`、`touchesCancelled`方法

UIResponder除了处理事件之外还管理着如何让未处理的事件传递到其它的responder对象。如果一个指定的responder对象未处理事件，那么它会沿着响应者链传递到另一个responder对象。当前下一个responder对象可能是`superView`或者`ViewController`。
**UIResponder的部分声明如下：**
```
@interface UIResponder : NSObject <UIResponderStandardEditActions>
@property(nonatomic, readonly, nullable) UIResponder *nextResponder;
@property(nonatomic, readonly) BOOL canBecomeFirstResponder;    // default is NO
@property(nonatomic, readonly) BOOL canResignFirstResponder;    // default  is YES
@property(nonatomic, readonly) BOOL isFirstResponder;
// 处理触摸事件的主要方法，所以我们自定义事件处理时，就需要在这几个方法里面做文章。
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event;
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event;
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event;
- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event;
- (void)touchesEstimatedPropertiesUpdated:(NSSet<UITouch *> *)touches NS_AVAILABLE_IOS(9_1);
//点按事件
- (void)pressesBegan:(NSSet<UIPress *> *)presses withEvent:(nullable UIPressesEvent *)event NS_AVAILABLE_IOS(9_0);
- (void)pressesChanged:(NSSet<UIPress *> *)presses withEvent:(nullable UIPressesEvent *)event NS_AVAILABLE_IOS(9_0);
- (void)pressesEnded:(NSSet<UIPress *> *)presses withEvent:(nullable UIPressesEvent *)event NS_AVAILABLE_IOS(9_0);
- (void)pressesCancelled:(NSSet<UIPress *> *)presses withEvent:(nullable UIPressesEvent *)event NS_AVAILABLE_IOS(9_0);
//加速事件
- (void)motionBegan:(UIEventSubtype)motion withEvent:(nullable UIEvent *)event NS_AVAILABLE_IOS(3_0);
- (void)motionEnded:(UIEventSubtype)motion withEvent:(nullable UIEvent *)event NS_AVAILABLE_IOS(3_0);
- (void)motionCancelled:(UIEventSubtype)motion withEvent:(nullable UIEvent *)event NS_AVAILABLE_IOS(3_0);
//远程控制事件
- (void)remoteControlReceivedWithEvent:(nullable UIEvent *)event NS_AVAILABLE_IOS(4_0);
@end
```

## 二、查找第一响应者
第一响应者的类型和事件的类型有关系：

| 事件类型          | 第一响应者 
|:-------------:| :-----:
| Touch events| The view in which the touch occurred. 
| Press events     |   The object that has focus.
| Shake-motion events     |    The object that you (or UIKit) designate.
| Remote-control events     |   The object that you (or UIKit) designate.
| Editing menu messages     |    The object that you (or UIKit) designate.
现在我们只关心触摸事件
**查找第一响应者的原理如下：**UIKit 会使用基于view的hit-testing方法来查找第一响应者。明确地说就是利用触摸发生的位置和视图层级中每个view的bounds进行比较(其实就是调用`pointInside:withEvent`,如果返回YES表示在这个范围内，NO则相反)。也就是说通过视图中的`hitTest:withEvent`方法遍历视图层级，直至找到包含触摸点的子view，那个view就是第一响应者。
- 备注：如果触摸点在一个view 的bounds之外，那么这个view及其它的子view将会被忽略。因此，当一view的clipsToBounds=NO，如果触摸事件发生在子view上超出父视图的部分，那么`hitTest:withEvent`也不会将这个子view返回。

下面利用一个demo来验证一下第一响应者查找的过程。
 
![图层.png](https://upload-images.jianshu.io/upload_images/1846524-0ba7acb50b749f74.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
视图的层级如下：
```
Window
    └── ViewA
        ├── ViewB
        └── ViewC
            ├── ViewD
            └── ViewE
```
现在点击ViewD,则相应的打印如下图：
```
Window范围内查找
Window-->hitTest:withEvent:
Window-->pointInside:withEvent:
Window-->pointInside:withEvent:-->是否包含第一响应者：1
ViewA范围内查找
ViewA-->hitTest:withEvent:
ViewA-->pointInside:withEvent:
ViewA-->pointInside:withEvent:-->是否包含第一响应者：1
ViewC范围内查找
ViewC-->hitTest:withEvent:
ViewC-->pointInside:withEvent:
ViewC-->pointInside:withEvent:-->是否包含第一响应者：1
ViewE范围内查找
ViewE-->hitTest:withEvent:
ViewE-->pointInside:withEvent:
ViewE-->pointInside:withEvent:-->是否包含第一响应者：0
ViewE-->hitTest:withEvent:-->FirstResponder：(null)
ViewD范围内查找
ViewD-->hitTest:withEvent:
ViewD-->pointInside:withEvent:
ViewD-->pointInside:withEvent:-->是否包含第一响应者：1
ViewD-->hitTest:withEvent:-->FirstResponder：<ViewD: 0x105213720; frame = (29 78; 106 65); autoresize = RM+BM; layer = <CALayer: 0x2835e8d60>>
ViewC-->hitTest:withEvent:-->FirstResponder：<ViewD: 0x105213720; frame = (29 78; 106 65); autoresize = RM+BM; layer = <CALayer: 0x2835e8d60>>
ViewA-->hitTest:withEvent:-->FirstResponder：<ViewD: 0x105213720; frame = (29 78; 106 65); autoresize = RM+BM; layer = <CALayer: 0x2835e8d60>>
Window-->hitTest:withEvent:-->FirstResponder：<ViewD: 0x105213720; frame = (29 78; 106 65); autoresize = RM+BM; layer = <CALayer: 0x2835e8d60>>
```
**结果分析：**
- 1.首先从`Window`开始,先调用`hitTest:withEvent:`，然后调用`pointInside:withEvent:`，因为触摸点确实在`Window`上所以`pointInside:withEvent:`返回了`true`
- 2.然后遍历`Window`的子视图`ViewA`, 调用`hitTest:withEvent:`，然后调用`pointInside:withEvent:`，因为触摸点确实在`ViewA`上所以`pointInside:withEvent:`返回了`true`
- 3.然后遍历`ViewA`的子视图(`ViewB`,`ViewC`),遍历采用的是从后往前(也即先遍历最后addSubview的视图，因为最后添加的视图通常情况下是在视图的最上层，苹果这里做了一个优化)。先遍历`ViewC`,操作同`Window`。
- 4.然后遍历`ViewC`的子视图(`ViewD`,`ViewE`)。同样，遍历采用的是从后往前。先遍历`ViewE`,操作同`Window`.这时`pointInside:withEvent:`返回了`false`，也即不包含触摸点。那么相应的`hitTest:withEvent`返回了null
- 5.遍历ViewD,因为ViewD已经是一个叶节点(iOS中视图的层级是一个n杈树)，其`pointInside:withEvent:`返回了true，与此相对应的`hitTest:withEvent`返回最终包含触摸点的视图，也即第一响应者。`hitTest:withEvent`的查找类似一个递归，所以在包含第一响应者的分支上的每一个视图中的`hitTest:withEvent`都返回第一个响应者。
- 6.因为已经找到了第一响应者，所以ViewB这个分支就没必要遍历了。

**官方文档明确指出，下面情况的视图不在遍历范围内：**
 - 视图的`hidden`等于`YES`。
 - 视图的`alpha`小于等于`0.01`。
 - 视图的`userInteractionEnabled`为`NO`。
也就是说在`hitTest:withEvent`调用过程中会进行上面三种情况的判断。

**伪代码大致如下：**
```
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event{
    //3种状态无法响应事件
     if (self.userInteractionEnabled == NO || self.hidden == YES ||  self.alpha <= 0.01) return nil; 
    //触摸点若不在当前视图上则无法响应事件
    if ([self pointInside:point withEvent:event] == NO) return nil; 
    //从后往前遍历子视图数组 
    int count = (int)self.subviews.count; 
    for (int i = count - 1; i >= 0; i--)  { 
        // 获取子视图
        UIView *childView = self.subviews[I]; 
        // 坐标系的转换,把触摸点在当前视图上坐标转换为在子视图上的坐标
        CGPoint childP = [self convertPoint:point toView:childView]; 
        //询问子视图层级中的最佳响应视图
        UIView *fitView = [childView hitTest:childP withEvent:event]; 
        if (fitView)  {
            //如果子视图中有更合适的就返回
            return fitView; 
        }
    } 
    //没有在子视图中找到更合适的响应视图，那么自身就是最合适的
    return self;
}
```
在找到第一响应者之后所有的信息全部包含在一个UIEvent对象中，接下来会通过sendEvent方法直接将事件传递给第一响应者。
![图片.png](https://upload-images.jianshu.io/upload_images/1846524-c1d09ff04a619ce4.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/600)
那么接下来就是响应者链处理的问题了。

## 三、响应者链

***所谓响应者链即有响应者对象组成的链条***

**下面是官方旧版本事件传递的过程：**
![响应者链.png](https://upload-images.jianshu.io/upload_images/1846524-e56c394248918912.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

上图解释如下：
- 触摸了`initial view`

- **1.**第一响应者就是`initial view`, 即`initial view`首先响应`touchesBegan:withEvent:`方法，如果其没有重写`touchesBegan:withEvent:`或者重写了但是调用了`super`方法那么事件会传递给橘黄色的view

- **2.**橘黄色的view开始响应`touchesBegan:withEvent:`方法，如果其没有重写`touchesBegan:withEvent:`或者重写了但是调用了`super`方法那么事件会传递给蓝绿色view

- **3.**蓝绿色view响应`touchesBegan:withEvent:`方法，如果其没有重写`touchesBegan:withEvent:`或者重写了但是调用了`super`方法那么事件会传递给控制器的view

- **4.**控制器view响应`touchesBegan:withEvent:`方法，如果其没有重写`touchesBegan:withEvent:`或者重写了但是调用了`super`方法那么事件会传递给控制器传递给了窗口

- **5.**窗口再传递给application
- 如果app不能处理这个事件，那么这个事件将被废弃

**下面是官方新版本事件传递的过程：**
![响应者链新.png](https://upload-images.jianshu.io/upload_images/1846524-3e44ce3ee639c7de.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
解释如下：
- 如果`text field`未处理事件，`UIKit`会将事件传递给`text field`中`parent view--UIView`,也即图中的第一个`UIView`,
- 如果第一个`UIView`未处理事件，`UIKit`会将事件传递给第二个`UIView`
- 如果第二个`UIView`未处理事件，正常情况下应该将事件传递给`UIWindow`。但是`UIViewController`也是`UIResponder`的子类，所以事件将传递给`UIViewController`
- 如果`UIViewController`未处理事件，`UIKit`会将事件传递给第`UIWindow`
- 如果`UIWindow`未处理事件，UIKit会将事件传递给第`UIApplication`，当然也会传递给是`UIResponder`的子类但不属于响应者链环节的`delegate`
- 如果app不能处理这个事件，那么这个事件将被废弃

## 四、Gesture Recognizer
 &#160;&#160;&#160;&#160;&#160;&#160;&#160;这里不着重讲解手势，如果想了解可以参考[官方文档](https://developer.apple.com/documentation/uikit/uigesturerecognizer)，这里主要分析手势和touch事件响应先后的问题。
 &#160;&#160;&#160;&#160;&#160;&#160;&#160;手势识别器是处理视图上触摸事件和按压事件最简单的方式。可以将一个或多个手势附加在视图上。 手势识别器包含了视图上必要的处理逻辑，当检测到一个手势时，手势会派发给指定的目标，这个目标可以是view controller ,view 或app中其它的对象。

**手势的模型图：**
![手势.png](https://upload-images.jianshu.io/upload_images/1846524-d754ed77a54ccd2c.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
**手势识别器工作原理：**
手势识别器的工作原理其实就是一个状态机。手势识别器从预设的状态中从一个状态转换到另一个状态。对于每一个状态，只要满足合适的条件就可以转换到下一步众多状态中的一个。根据是否手势是否是离散的，状态机有下面两种：
 ![状态机.png](https://upload-images.jianshu.io/upload_images/1846524-fbd83b5b75925c08.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/900)
上图解释如下：
- 手势识别器都是以`Possible (UIGestureRecognizerStatePossible)`状态为起始。
- 手势识别器分析接收到的触摸事件，如果失败状态变为`Failed(UIGestureRecognizerStateFailed)`
- 对于离散的手势如果识别成功状态变为`Recognized (UIGestureRecognizerStateRecognized)`,至此识别结束
- 对于连续的手势，当第一次被识别的时候状态从`Possible`状态转换到`Began (UIGestureRecognizerStateBegan) `,然后从`Began`状态转换到`Changed (UIGestureRecognizerStateChanged)`，当手势发生的时候开持续的从`Changed`状态转换到`Changed`状态。
- 如果连续的手势不再满足相应的模式，那么它会 从`Changed` 转换到 `Canceled (UIGestureRecognizerStateCancelled)`状态，比如在触摸的时候，突然来了一个电话，这里就会进入 `Canceled`.
- 如果连续的手势识别成功就会进入 `Recognized `状态，并重置状态机到`Possible`状态

**手势和触摸事件的优先级：**
> Gesture Recognizers Get the First Opportunity to Recognize a Touch
> #`手势优先获取事件`
> A window delays the delivery of touch objects to the view so that the gesture recognizer can analyze the touch first. During the delay, if the gesture recognizer recognizes a touch gesture, then the window never delivers the touch object to the view, and also cancels any touch objects it previously sent to the view that were part of that recognized sequence.
>`Window 对象会延迟将“触摸对”象发送给视图，从而让手势识别器最先对“触摸” 进行分析处理。在延迟期间，如果识别器成功识别触摸手势，window 对象就不会再将“触摸对象”传递给视图对象，并取消本应在手势序列中而且可以接受触摸事件的触摸对象`

也就是说view上触摸事件的优先级要比view上的手势的优先级低。再放一张图：
![图片.png](https://upload-images.jianshu.io/upload_images/1846524-7ba303823b333f91.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

#### 4.1、当前view添加手势
在`图层.png`这个图片中,给ViewD添加一个手势，当前触摸ViewD的时候打印如下数据：
```
Window范围内查找

/*
省略无关代码
*/
Window-->hitTest:withEvent:-->FirstResponder：<ViewD: 0x105213720; frame = (29 78; 106 65); autoresize = RM+BM; layer = <CALayer: 0x2835e8d60>>
/**下面是添加手势之后打印的数据**/
ViewD -- touchesBegan
ViewD -- tapGesture
ViewD -- touchesCancelled
```

注： 如果同一个视图如果添加多个相同的手势，经测试最后一个生效

#### 4.2、当前view和superview同时添加手势
同时给ViewC和ViewD添加手势，执行的仍然是viewD的手势。
/**下面是添加手势之后打印的数据**/
ViewD -- touchesBegan
ViewD -- tapGesture
ViewD -- touchesCancelled
```
如果不为ViewD添加手势执行的是ViewC的手势。
/**下面是添加手势之后打印的数据**/
ViewD -- touchesBegan
ViewC-- tapGesture
ViewD -- touchesEnded
```
注意打印数据对比，ViewD没有添加手势，先执行ViewC的手势，然后执行ViewD的触摸方法，而同一个ViewC添加手势，则会取消当前的触摸事件。


**cancelsTouchesInView**
默认为YES。表示当手势识别器成功识别了手势之后，会通知Application取消响应链对事件的响应，并不再传递事件给hit-test view。若设置成NO，表示手势识别成功后不取消响应链对事件的响应，事件依旧会传递给hit-test view。


**delaysTouchesBegan**
默认为NO。默认情况下手势识别器在识别手势期间，当触摸状态发生改变时，Application都会将事件传递给手势识别器和hit-tested view；若设置成YES，则表示手势识别器在识别手势期间，截断事件，即不会将事件发送给hit-tested view。也就是说从`touchesBegan`后续的流程都不再调用。

**delaysTouchesEnded**
默认为YES。当手势识别失败时，若此时触摸已经结束，会延迟一小段时间（0.15s）再调用响应者的 touchesEnded:withEvent:；若设置成NO，则在手势识别失败时会立即通知Application发送状态为end的touch事件给hit-tested view以调用 touchesEnded:withEvent: 结束事件响应。

## 五、UIControl
UIControl是系统提供的能够以target-action模式处理触摸事件的控件，iOS中UIButton、UISegmentedControl、UISwitch等控件都是UIControl的子类。当UIControl跟踪到触摸事件时，会向其上添加的target发送事件以执行action。值得注意的是，UIConotrol是UIView的子类，故具有和UIResponder同样的行为。
下面是UIControl内部的四个方法，因为只能接收一个UITouch对象，所以UIControl只能是单点触摸。
```
- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(nullable UIEvent *)event;
- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(nullable UIEvent *)event;
- (void)endTrackingWithTouch:(nullable UITouch *)touch withEvent:(nullable UIEvent *)event;
- (void)cancelTrackingWithEvent:(nullable UIEvent *)event;
```
#### 5.1、UIControl重写touch方法

代码
```
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//    [super touchesBegan:touches withEvent:event]; //对于UIControl在其内部自动调用beginTrackingWithTouch，下面方法类似调用相应的方法
    NSLog(@"CustomButton -- touchesBegan");
}
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//    [super touchesEnded:touches withEvent:event];
    NSLog(@"CustomButton -- touchesEnded");
}
- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//    [super touchesCancelled:touches withEvent:event];
    NSLog(@"CustomButton -- touchesCancelled");
}
```
打印结果：没有打印UIButton的点击方法
```
CustomButton -- touchesBegan
CustomButton -- touchesEnded
```
如果touch方法调用super，打印结果如下：
```
CustomButton -- touchesBegan
CustomButton-- ButtonDidClick
CustomButton -- touchesEnded
```
> 可见touch内部自动调用了UIControl相应的方法,所以UIControl也是基于touch实现的

#### 5.2、UIControl添加手势
结果如下：
```
CustomButton -- touchesBegan
CustomButton-- buttonTapGesture
CustomButton -- touchesCancelled
```
> 结果分析：手势取消了触摸事件，同样也取消了按钮的事件。如果将手势的cancelsTouchesInView 设置成false，则触摸，手势和按钮的事件同时响应，依然是手势优先执行。

#### 5.3、UIControl的父视图添加手势
打印结果如下 ：
```
CustomButton -- touchesBegan
CustomButton-- ButtonDidClick
CustomButton -- touchesEnded
```
结果分析：UIControl的事件屏蔽了父视图的手势,如果不想屏幕父视图的手势 可将cancelsTouchesInView 设置成false，这时优先响应手势，再响应UIControl的事件

如果放`cancelsTouchesInView `设置成false,打印结果如下：

```ruby
CustomButton -- touchesBegan
ViewB-- tapGesture
CustomButton-- ButtonDidClick
CustomButton -- touchesEnded
```
可以看出还是手势的优先级相对高

> **结论：默认情况下UIControl比其父视图上的手势识别器具有更高的事件响应优先级。**

###参考资料
[demo](https://github.com/tsc000/Exploration/tree/master/ResponderChain)
[UIGestureRecognizer](https://developer.apple.com/documentation/uikit/uigesturerecognizer)
[Touches, Presses, and Gestures](https://developer.apple.com/documentation/uikit/touches_presses_and_gestures?language=objc)




