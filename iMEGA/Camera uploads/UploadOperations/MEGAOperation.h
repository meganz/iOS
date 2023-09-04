#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 'MEGAOperation' is a simple concurrent operation with the ability to monitor the states of the running operation.
 It can be executed either mannually or in an operation queue.
 */
@interface MEGAOperation : NSOperation

/**
 Start executing tasks and update the `isExecuting` property
 */
- (void)startExecuting;

/**
 Stop running the operation and mark the state to finished
 */
- (void)finishOperation;


/**
 Cancel the operation and make the state to finished
 */
- (void)cancelOperation;

@end

NS_ASSUME_NONNULL_END
