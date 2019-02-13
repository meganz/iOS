
#import <Foundation/Foundation.h>
@import Photos;

NS_ASSUME_NONNULL_BEGIN

@class PHAsset, MEGANode;

@interface CameraUploadManager : NSObject

@property (readonly) NSUInteger uploadPendingItemsCount;
@property (readonly) BOOL isNodesFetchDone;
@property (nonatomic, getter=isPhotoUploadPaused) BOOL pausePhotoUpload;
@property (nonatomic, getter=isVideoUploadPaused) BOOL pauseVideoUpload;
@property (readonly) BOOL isCameraUploadPausedByDiskFull;

/**
 @return a shared camera upload manager instance
 */
+ (instancetype)shared;

#pragma mark - start upload

- (void)setupCameraUploadWhenAppLaunches;

- (void)startCameraUploadIfNeeded;
- (void)startVideoUploadIfNeeded;

- (void)uploadNextAssetWithMediaType:(PHAssetMediaType)mediaType;

#pragma mark - stop upload

- (void)stopCameraUpload;
- (void)stopVideoUpload;

#pragma mark - pause and resume upload

- (void)pauseCameraUploadIfNeeded;
- (void)resumeCameraUpload;

#pragma mark - background refresh

+ (void)enableBackgroundRefreshIfNeeded;
+ (void)disableBackgroundRefresh;

- (void)performBackgroundRefreshWithCompletion:(void (^)(UIBackgroundFetchResult))completion;

#pragma mark - background upload

- (void)startBackgroundUploadIfPossible;
- (void)stopBackgroundUpload;

#pragma mark - request camera upload node

- (void)requestCameraUploadNodeWithCompletion:(void (^)(MEGANode * _Nullable cameraUploadNode))completion;

@end

NS_ASSUME_NONNULL_END
