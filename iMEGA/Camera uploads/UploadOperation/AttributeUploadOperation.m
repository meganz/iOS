
#import "AttributeUploadOperation.h"

static NSString * const AttributeErrorDomain = @"nz.mega.cameraUpload.attibuteUpload";
static NSString * const AttributeErrorMessageKey = @"message";

@interface AttributeUploadOperation ()

@property (nonatomic) UIBackgroundTaskIdentifier backgroundTaskId;

@end

@implementation AttributeUploadOperation

- (instancetype)initWithNode:(MEGANode *)node uploadInfo:(AssetUploadInfo *)uploadInfo {
    self = [super init];
    if (self) {
        _node = node;
        _uploadInfo = uploadInfo;
    }
    
    return self;
}

- (void)start {
    [super start];
    
    self.backgroundTaskId = [UIApplication.sharedApplication beginBackgroundTaskWithName:@"attributeUploadBackgroundTask" expirationHandler:^{
        [self finishOperationWithError:[self errorWithMessage:[NSString stringWithFormat:@"Background task expired in uploading attribute for asset: %@", self.uploadInfo.asset.localIdentifier]]];
    }];
}

- (NSError *)errorWithMessage:(NSString *)message {
    return [NSError errorWithDomain:AttributeErrorDomain code:0 userInfo:@{AttributeErrorMessageKey : [NSString stringWithFormat:@"%@ %@", NSStringFromClass(self.class), message]}];
}

- (void)expireOperation {
    [self finishOperationWithError:[self errorWithMessage:@"operation gets expired"]];
}

- (void)finishOperationWithError:(NSError *)error {
    [super finishOperation];
    
    MEGALogDebug(@"[Camera Upload] %@ operation finished with error: %@", NSStringFromClass(self.class), error);
    
    [UIApplication.sharedApplication endBackgroundTask:self.backgroundTaskId];
    self.backgroundTaskId = UIBackgroundTaskInvalid;
}

@end
