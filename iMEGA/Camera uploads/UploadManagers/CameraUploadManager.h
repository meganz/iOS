
#import <Foundation/Foundation.h>
@import Photos;

NS_ASSUME_NONNULL_BEGIN

@class PHAsset, MEGANode;

@interface CameraUploadManager : NSObject

@property (readonly) NSUInteger uploadPendingItemsCount;
@property (readonly) BOOL isNodesFetchDone;

/**
 @return a singleton camera upload manager instance
 */
+ (instancetype)shared;

#pragma mark - camera upload management

- (void)configCameraUploadWhenAppLaunches;

- (void)startCameraUploadIfNeeded;
- (void)startVideoUploadIfNeeded;

- (void)stopCameraUpload;
- (void)stopVideoUpload;

- (void)uploadNextAssetWithMediaType:(PHAssetMediaType)mediaType;

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
