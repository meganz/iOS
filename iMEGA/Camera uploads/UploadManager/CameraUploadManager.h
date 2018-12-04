
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class PHAsset;

@interface CameraUploadManager : NSObject

@property (nonatomic, readonly) NSUInteger uploadRunningItemsCount;
@property (nonatomic, readonly) NSUInteger uploadPendingItemsCount;

+ (instancetype)shared;

- (void)startCameraUploadIfNeeded;
- (void)startVideoUploadIfNeeded;

- (void)uploadNextForAsset:(PHAsset *)asset;

- (void)stopCameraUpload;
- (void)stopVideoUpload;

@end

NS_ASSUME_NONNULL_END
