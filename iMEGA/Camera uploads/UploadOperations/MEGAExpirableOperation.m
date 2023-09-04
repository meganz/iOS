#import "MEGAExpirableOperation.h"

@interface MEGAExpirableOperation ()

@property (strong, nonatomic) dispatch_source_t expireTimer;
@property (nonatomic) NSTimeInterval expireTimeInterval;

@end

@implementation MEGAExpirableOperation

- (instancetype)initWithExpireTimeInterval:(NSTimeInterval)timeInterval {
    self = [super init];
    if (self) {
        _expireTimeInterval = timeInterval;
    }
    return self;
}

- (void)start {
    [super start];
    
    self.expireTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(QOS_CLASS_UTILITY, 0));
    dispatch_source_set_timer(self.expireTimer, dispatch_walltime(NULL, (int64_t)(self.expireTimeInterval * NSEC_PER_SEC)), (uint64_t)(self.expireTimeInterval * NSEC_PER_SEC), 1 * NSEC_PER_SEC);
    
    __weak __typeof__(self) weakSelf = self;
    dispatch_source_set_event_handler(self.expireTimer, ^{
        [weakSelf timerExpired];
    });
    
    dispatch_resume(self.expireTimer);
}

- (void)timerExpired {
    MEGALogDebug(@"%@ expired after time interval %.2f", self, self.expireTimeInterval);
    [self finishOperation];
}

- (void)finishOperation {
    [super finishOperation];
    if (self.expireTimer) {
        dispatch_source_cancel(self.expireTimer);
    }
}

@end
