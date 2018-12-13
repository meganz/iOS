
#import "MEGABackgroundTaskOperation.h"
#import "AssetUploadInfo.h"
#import "MEGASdkManager.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^UploadCompletionHandler)(MEGANode  * _Nullable node, NSError * _Nullable error);

@interface UploadCompletionOperation : MEGABackgroundTaskOperation

- (instancetype)initWithUploadInfo:(AssetUploadInfo *)info transferToken:(NSData *)token completion:(UploadCompletionHandler)completion;

@end

NS_ASSUME_NONNULL_END
