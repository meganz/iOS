#import "AssetUploadInfo.h"
#import "MEGASdkManager.h"
#import "MEGABackgroundTaskOperation.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^PutNodeCompletionHandler)(MEGANode  * _Nullable node, NSError * _Nullable error);

@interface PutNodeOperation : MEGABackgroundTaskOperation

@property (strong, nonatomic) AssetUploadInfo *uploadInfo;

- (instancetype)initWithUploadInfo:(AssetUploadInfo *)info transferToken:(NSData *)token completion:(PutNodeCompletionHandler)completion;

@end

NS_ASSUME_NONNULL_END
