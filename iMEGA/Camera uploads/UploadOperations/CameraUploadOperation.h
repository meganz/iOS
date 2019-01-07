
#import <UIKit/UIKit.h>
#import "MEGAOperation.h"
#import "AssetUploadInfo.h"
#import "MEGABackgroundTaskOperation.h"

NS_ASSUME_NONNULL_BEGIN

/**
 A base class for camera upload operation. It's supposed to be subclassed.
 */
@interface CameraUploadOperation :  MEGABackgroundTaskOperation

@property (strong, nonatomic) AssetUploadInfo *uploadInfo;

- (instancetype)initWithUploadInfo:(AssetUploadInfo *)uploadInfo;

- (void)encryptsFile;

- (MEGANode *)nodeForOriginalFingerprint:(NSString *)fingerprint;

- (void)finishUploadForFingerprintMatchedNode:(MEGANode *)node;

- (void)finishOperationWithStatus:(NSString *)status shouldUploadNextAsset:(BOOL)uploadNextAsset;

@end

NS_ASSUME_NONNULL_END
