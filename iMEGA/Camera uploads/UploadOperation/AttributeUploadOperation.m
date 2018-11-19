
#import "AttributeUploadOperation.h"

@interface AttributeUploadOperation ()

@property (strong, nonatomic) NSTimer *watchTimer;
@property (nonatomic) NSTimeInterval expireTimeInterval;

@end

@implementation AttributeUploadOperation

- (instancetype)initWithNode:(MEGANode *)node uploadInfo:(AssetUploadInfo *)uploadInfo expiresAfterTimeInterval:(NSTimeInterval)timeInterval {
    self = [super init];
    if (self) {
        _node = node;
        _uploadInfo = uploadInfo;
        _expireTimeInterval = timeInterval;
    }
    
    return self;
}

- (void)start {
    [super start];
    
    __weak __typeof__(self) weakSelf = self;
    self.watchTimer = [NSTimer scheduledTimerWithTimeInterval:self.expireTimeInterval repeats:NO block:^(NSTimer * _Nonnull timer) {
        MEGALogDebug(@"[Camera Upload] %@ expired with watch timer", NSStringFromClass(weakSelf.class));
        [weakSelf finishOperation];
    }];
}

- (void)finishOperation {
    [super finishOperation];
    
    MEGALogDebug(@"[Camera Upload] %@ operation finished", NSStringFromClass(self.class));
    [self.watchTimer invalidate];
}

@end
