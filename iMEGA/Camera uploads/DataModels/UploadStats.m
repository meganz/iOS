#import "UploadStats.h"

@implementation UploadStats

- (instancetype)initWithFinishedCount:(NSUInteger)finishedCount totalCount:(NSUInteger)totalCount {
    self = [super init];
    if (self) {
        _finishedFilesCount = finishedCount;
        _totalFilesCount = totalCount;
    }
    
    return self;
}

- (NSUInteger)pendingFilesCount {
    return self.totalFilesCount - self.finishedFilesCount;
}

- (BOOL)isUploadCompleted {
    return self.pendingFilesCount == 0;
}

- (float)progress {
    if (self.totalFilesCount == 0) {
        return 1.0f;
    } else {
        return (float)self.finishedFilesCount / (float)self.totalFilesCount;
    }
}

@end
