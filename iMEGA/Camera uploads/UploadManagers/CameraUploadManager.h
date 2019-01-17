
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

+ (void)disableCameraUploadIfAccessProhibited;

- (void)startCameraUploadIfNeeded;
- (void)startVideoUploadIfNeeded;

- (void)stopCameraUpload;
- (void)stopVideoUpload;

- (void)uploadNextForAsset:(PHAsset *)asset;

#pragma mark - upload records collation

- (void)collateUploadRecords;

#pragma mark - photo library scan

- (void)scanPhotoLibraryWithCompletion:(void (^)(void))completion;

#pragma mark - background refresh

+ (void)enableBackgroundRefreshIfNeeded;
+ (void)disableBackgroundRefresh;

#pragma mark - background upload

- (void)startBackgroundUploadIfPossible;
- (void)stopBackgroundUpload;

@end

NS_ASSUME_NONNULL_END
