
#import <Foundation/Foundation.h>
#import "UploadStats.h"
@import Photos;

NS_ASSUME_NONNULL_BEGIN

@class PHAsset, MEGANode;

@interface CameraUploadManager : NSObject

@property (readonly) BOOL isNodeTreeCurrent;
@property (nonatomic, getter=isPhotoUploadPaused) BOOL pausePhotoUpload;
@property (nonatomic, getter=isVideoUploadPaused) BOOL pauseVideoUpload;
@property (readonly) BOOL isDiskStorageFull;

/**
 @return a shared camera upload manager instance
 */
+ (instancetype)shared;

#pragma mark - setup camera upload

- (void)setupCameraUploadWhenApplicationLaunches:(UIApplication *)application;

#pragma mark - start upload

- (void)startCameraUploadIfNeeded;
- (void)startVideoUploadIfNeeded;

- (void)uploadNextAssetForMediaType:(PHAssetMediaType)mediaType;

#pragma mark - enable camera upload

- (void)enableCameraUpload;
- (void)enableVideoUpload;

#pragma mark - disable camera upload

- (void)disableCameraUpload;
- (void)disableVideoUpload;

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

#pragma mark - fetch upload stats

- (void)loadCurrentUploadStats:(void (^)(UploadStats * _Nullable uploadStats, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
