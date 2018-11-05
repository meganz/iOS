
#import "VideoUploadOperation.h"

@implementation VideoUploadOperation

#pragma mark - operation lifecycle

- (void)start {
    [super start];
}

- (void)dealloc {
    MEGALogDebug(@"video upload operation gets deallocated");
}

#pragma mark - property

- (NSString *)cameraUploadBackgroundTaskName {
    return @"nz.mega.cameraUpload.video";
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Video upload operation %@", self.uploadInfo.asset.localIdentifier];
}

#pragma mark - data processing

@end
