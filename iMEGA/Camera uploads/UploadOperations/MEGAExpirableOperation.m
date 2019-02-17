
#import "MEGAExpirableOperation.h"

@interface MEGAExpirableOperation ()

@property (strong, nonatomic) NSTimer *expireTimer;
@property (nonatomic) NSTimeInterval expireTimeInterval;

@end

@implementation MEGAExpirableOperation

- (instancetype)initWithExpirationTimeInterval:(NSTimeInterval)timeInterval {
    self = [super init];
    if (self) {
        _expireTimeInterval = timeInterval;
    }
    return self;
}

- (void)start {
    [super start];
    
    [self beginBackgroundTaskWithExpirationHandler:^{
        [self finishOperation];
    }];
    
    __weak __typeof__(self) weakSelf = self;
    self.expireTimer = [NSTimer scheduledTimerWithTimeInterval:self.expireTimeInterval repeats:NO block:^(NSTimer * _Nonnull timer) {
        MEGALogDebug(@"%@ expired after time interval %.2f", weakSelf, self.expireTimeInterval);
        [weakSelf finishOperation];
    }];
}

- (void)finishOperation {
    [super finishOperation];
    if (self.expireTimer.isValid) {
        [self.expireTimer invalidate];
    }
}


@end
