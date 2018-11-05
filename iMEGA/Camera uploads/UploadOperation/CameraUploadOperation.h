
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
@property (nonatomic) UIBackgroundTaskIdentifier uploadTaskIdentifier;
@property (strong, nonatomic) CameraUploadCoordinator *uploadCoordinator;
@property (nonatomic, readonly) NSString *cameraUploadBackgroundTaskName;
@property (strong, nonatomic, nullable) MEGASdk *attributesDataSDK;

- (instancetype)initWithUploadInfo:(AssetUploadInfo *)uploadInfo;

- (void)finishOperationWithStatus:(NSString *)status shouldUploadNextAsset:(BOOL)uploadNextAsset;
- (void)archiveUploadInfoDataIfNeeded;
- (void)uploadFileToServer;
- (void)processExistingNode:(MEGANode *)node;

@end

NS_ASSUME_NONNULL_END
