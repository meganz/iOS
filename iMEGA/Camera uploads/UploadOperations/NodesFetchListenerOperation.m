
#import "NodesFetchListenerOperation.h"
#import "CameraUploadManager.h"
#import "MEGAConstants.h"

@implementation NodesFetchListenerOperation

- (void)start {
    [super start];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(finishOperation) name:MEGANodesCurrentNotificationName object:nil];
    if (CameraUploadManager.shared.isNodeTreeCurrent) {
        [self finishOperation];
    }
}

- (void)finishOperation {
    [super finishOperation];
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

@end
