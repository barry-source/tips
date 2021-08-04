
#import <Foundation/Foundation.h>

typedef void (^PermenantThreadTask)(void);

@interface PermenantThread : NSObject

/**
 在当前子线程执行一个任务
 */
- (void)executeTask:(PermenantThreadTask)task;

/**
 结束线程
 */
- (void)stop;

@end
