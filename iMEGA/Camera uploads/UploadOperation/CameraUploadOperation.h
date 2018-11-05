
#import <UIKit/UIKit.h>
#import "MEGAOperation.h"
#import "AssetUploadInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface CameraUploadOperation : MEGAOperation

- (instancetype)initWithUploadInfo:(AssetUploadInfo *)uploadInfo;

- (void)finishOperationWithStatus:(NSString *)status shouldUploadNextAsset:(BOOL)uploadNextAsset;

@end

NS_ASSUME_NONNULL_END
