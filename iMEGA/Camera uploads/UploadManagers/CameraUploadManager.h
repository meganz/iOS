
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class PHAsset;

@interface CameraUploadManager : NSObject

@property (nonatomic, readonly) NSUInteger uploadPendingItemsCount;

/**
 @return a singleton camera upload manager instance
 */
+ (instancetype)shared;

#pragma mark - camera upload management

+ (void)configCameraUploadWhenAppLaunches;

- (void)startCameraUploadIfNeeded;
- (void)startVideoUploadIfNeeded;

- (void)stopCameraUpload;
- (void)stopVideoUpload;

- (void)uploadNextForAsset:(PHAsset *)asset;

#pragma mark - background refresh

+ (void)enableBackgroundRefreshIfNeeded;
+ (void)disableBackgroundRefresh;

- (void)performBackgroundRefreshWithCompletion:(void (^)(UIBackgroundFetchResult))completion;

#pragma mark - background upload

- (void)startBackgroundUploadIfPossible;
- (void)stopBackgroundUpload;

@end

NS_ASSUME_NONNULL_END
