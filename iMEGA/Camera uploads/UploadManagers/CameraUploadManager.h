
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class PHAsset;

@interface CameraUploadManager : NSObject

@property (nonatomic, readonly) NSUInteger uploadPendingItemsCount;

+ (instancetype)shared;

+ (void)disableCameraUploadIfNoAccess;

- (void)startCameraUploadIfNeeded;
- (void)startVideoUploadIfNeeded;

- (void)stopCameraUpload;
- (void)stopVideoUpload;

- (void)uploadNextForAsset:(PHAsset *)asset;

- (void)collateUploadRecords;

- (void)scanPhotoLibraryWithCompletion:(void (^)(void))completion;

@end

NS_ASSUME_NONNULL_END
