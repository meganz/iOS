
#import "MEGAExpirableOperation.h"

@interface MEGAExpirableOperation ()

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
    
    __weak __typeof__(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.expireTimeInterval * NSEC_PER_SEC)), dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        MEGALogDebug(@"%@ expired", weakSelf);
        [weakSelf finishOperation];
    });
}

- (void)finishOperation {
    [super finishOperation];
}


@end
