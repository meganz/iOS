
#import "MEGAOperation.h"
#import "AssetUploadInfo.h"
#import "MEGASdkManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface PreviewUploadOperation : MEGAOperation

- (instancetype)initWithNode:(MEGANode *)node uploadInfo:(AssetUploadInfo *)uploadInfo;

- (void)expireOperation;

@end

NS_ASSUME_NONNULL_END
