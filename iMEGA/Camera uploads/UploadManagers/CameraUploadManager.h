
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class PHAsset;

@interface CameraUploadManager : NSObject

@property (nonatomic, readonly) NSUInteger uploadRunningItemsCount;
@property (nonatomic, readonly) NSUInteger uploadPendingItemsCount;

+ (instancetype)shared;

- (void)enableCameraUpload;

- (void)startCameraUploadIfNeeded;
- (void)startVideoUploadIfNeeded;

- (void)disableCameraUpload;
- (void)disableVideoUpload;

- (void)uploadNextForAsset:(PHAsset *)asset;

- (void)collateUploadRecords;
- (void)retryAttributeFileUploads;

@end

NS_ASSUME_NONNULL_END
