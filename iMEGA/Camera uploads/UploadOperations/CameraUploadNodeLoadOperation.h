
#import "MEGAOperation.h"
#import "MEGASdkManager.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^CameraUploadNodeLoadCompletionHandler)(MEGANode * _Nullable cameraUploadNode, NSError * _Nullable error);

@interface CameraUploadNodeLoadOperation : MEGAOperation

- (instancetype)initWithLoadCompletion:(CameraUploadNodeLoadCompletionHandler)completion;

@end

NS_ASSUME_NONNULL_END
