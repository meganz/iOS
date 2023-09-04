#import "MEGAOperation.h"

@implementation MEGAOperation

@synthesize executing, finished;

/**
 It's not recommended to call [super start] in MEGAOperation subclasses. According to different situations, each subclass may
 need to do things differently in the start method. For example, a subclass may want to make sure it's completion handler is called
 when to finish the operation.
 */
- (void)start {
    if (self.isFinished) {
        return;
    }

    if (self.isCancelled) {
        [self finishOperation];
        return;
    }
    
    [self startExecuting];
}

- (void)startExecuting {
    [self willChangeValueForKey:@"isExecuting"];
    executing = YES;
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)finishOperation {
    if (self.isFinished) {
        return;
    }
    
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    executing = NO;
    finished = YES;
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

- (void)cancelOperation {
    [self cancel];
    [self finishOperation];
}

- (BOOL)isExecuting {
    return executing;
}

- (BOOL)isFinished {
    return finished;
}

- (BOOL)isAsynchronous {
    return YES;
}

@end
