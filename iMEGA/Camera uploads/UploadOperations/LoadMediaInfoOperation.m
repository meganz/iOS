#import "LoadMediaInfoOperation.h"
#import "MEGASdkManager.h"

@implementation LoadMediaInfoOperation

- (void)start {
    [super start];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(didReceiveMediaInfoReadyNotification) name:MEGAMediaInfoReadyNotification object:nil];
    
    if ([MEGASdkManager.sharedMEGASdk ensureMediaInfo]) {
        [self finishOperation];
    }
}

- (void)finishOperation {
    [super finishOperation];
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

#pragma mark - Notification handler

- (void)didReceiveMediaInfoReadyNotification {
    [self finishOperation];
}

@end
