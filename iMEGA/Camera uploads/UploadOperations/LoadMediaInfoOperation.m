
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
    [self finishOperation];
}

@end
