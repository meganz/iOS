
#import "NodesFetchListenerOperation.h"
#import "CameraUploadManager.h"
#import "MEGAConstants.h"

@implementation NodesFetchListenerOperation

- (void)start {
    [super start];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(finishOperation) name:MEGANodesFetchDoneNotificationName object:nil];
    if (CameraUploadManager.shared.isNodesFetchDone) {
        [self finishOperation];
    }
}

- (void)finishOperation {
    [super finishOperation];
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

@end
