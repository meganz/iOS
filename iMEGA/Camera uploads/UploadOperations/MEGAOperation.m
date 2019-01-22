
#import "MEGAOperation.h"

@implementation MEGAOperation

@synthesize executing, finished;

- (void)start {
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
