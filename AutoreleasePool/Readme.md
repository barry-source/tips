
# AutoreleasePool

## 1、RunLoop概念

自动释放池的主要底层数据结构是：__AtAutoreleasePool、AutoreleasePoolPage

调用了autorelease的对象最终都是通过AutoreleasePoolPage对象来管理的
