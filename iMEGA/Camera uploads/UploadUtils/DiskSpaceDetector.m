
#import "DiskSpaceDetector.h"
#import "MEGAConstants.h"

@implementation DiskSpaceDetector

- (instancetype)init {
    self = [super init];
    if (self) {
        [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(diskSpaceFullNotification) name:MEGACameraUploadNoEnoughDiskSpaceNotificationName object:nil];
    }

    return self;
}

- (void)diskSpaceFullNotification {
    
}

@end
