
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
    
    self.expireTimer = [NSTimer scheduledTimerWithTimeInterval:self.expireTimeInterval target:self selector:@selector(timerExpired) userInfo:nil repeats:NO];
}

- (void)timerExpired {
    MEGALogDebug(@"%@ expired after time interval %.2f", self, self.expireTimeInterval);
    [self finishOperation];
}

- (void)finishOperation {
    [super finishOperation];
    if (self.expireTimer.isValid) {
        [self.expireTimer invalidate];
    }
}


@end
