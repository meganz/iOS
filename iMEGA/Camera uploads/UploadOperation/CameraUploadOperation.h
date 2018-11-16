
#import <UIKit/UIKit.h>
#import "MEGAOperation.h"
#import "AssetUploadInfo.h"
#import "CameraUploadCoordinator.h"

NS_ASSUME_NONNULL_BEGIN

/**
 A base class for camera upload operation. It's supposed to be subclassed.
 */
@interface CameraUploadOperation : MEGAOperation

@property (strong, nonatomic) AssetUploadInfo *uploadInfo;

- (instancetype)initWithUploadInfo:(AssetUploadInfo *)uploadInfo;

- (void)finishOperationWithStatus:(NSString *)status shouldUploadNextAsset:(BOOL)uploadNextAsset;
- (void)uploadFileToServer;
- (void)copyToParentNodeIfNeededForMatchingNode:(MEGANode *)node;
- (MEGANode *)nodeForOriginalFingerprint:(NSString *)fingerprint;
- (nullable NSURL *)URLForAssetFolder;

@end

NS_ASSUME_NONNULL_END
