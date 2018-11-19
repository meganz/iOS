
#import "MEGATaskOperation.h"
#import "AssetUploadInfo.h"
#import "MEGASdkManager.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^CompleteUploadCompletionHandler)(MEGANode  * _Nullable node, NSError * _Nullable error);

@interface CompleteUploadOperation : MEGATaskOperation

- (instancetype)initWithUploadInfo:(AssetUploadInfo *)info transferToken:(NSData *)token completion:(CompleteUploadCompletionHandler)completion;

@end

NS_ASSUME_NONNULL_END
