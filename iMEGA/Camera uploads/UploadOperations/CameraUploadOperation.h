
#import <UIKit/UIKit.h>
#import "MEGAOperation.h"
#import "AssetUploadInfo.h"
#import "MEGABackgroundTaskOperation.h"

NS_ASSUME_NONNULL_BEGIN

@class MOAssetUploadRecord;

/**
 A base class for camera upload operation. It's supposed to be subclassed.
 */
@interface CameraUploadOperation :  MEGABackgroundTaskOperation

@property (strong, nonatomic) AssetUploadInfo *uploadInfo;

- (instancetype)initWithUploadInfo:(AssetUploadInfo *)uploadInfo uploadRecord:(MOAssetUploadRecord *)uploadRecord;

- (void)handleProcessedUploadFile;

- (MEGANode *)nodeForOriginalFingerprint:(NSString *)fingerprint;

- (void)finishUploadForFingerprintMatchedNode:(MEGANode *)node;

- (void)finishUploadWithNoEnoughDiskSpace;

- (void)finishOperationWithStatus:(NSString *)status shouldUploadNextAsset:(BOOL)uploadNextAsset;

@end

NS_ASSUME_NONNULL_END
