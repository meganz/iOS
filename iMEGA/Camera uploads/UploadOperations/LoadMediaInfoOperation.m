
#import "LoadMediaInfoOperation.h"
#import "MEGASdkManager.h"

@interface LoadMediaInfoOperation () <MEGAGlobalDelegate>

@end

@implementation LoadMediaInfoOperation

- (void)start {
    [super start];
    
    [MEGASdkManager.sharedMEGASdk addMEGAGlobalDelegate:self];
    
    if ([MEGASdkManager.sharedMEGASdk ensureMediaInfo]) {
        [self finishOperation];
    }
}

- (void)finishOperation {
    [super finishOperation];
    [MEGASdkManager.sharedMEGASdk removeMEGAGlobalDelegate:self];
}

#pragma mark - MEGAGlobalDelegate

- (void)onMediaDetectionAvailable {
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        [self finishOperation];
    });
}

@end
