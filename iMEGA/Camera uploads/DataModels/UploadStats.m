
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

- (float)progress {
    return (float)self.finishedFilesCount / (float)self.totalFilesCount;
}

@end
