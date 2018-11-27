
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class PHAsset;

@interface CameraUploadManager : NSObject

@property (class, nonatomic, getter=isCameraUploadEnabled) BOOL cameraUploadEnabled;
@property (class, nonatomic, getter=isVideoUploadEnabled) BOOL videoUploadEnabled;
@property (class, nonatomic, getter=isCellularUploadEnabled) BOOL cellularUploadEnabled;

@property (nonatomic, readonly) NSUInteger uploadRunningItemsCount;
@property (nonatomic, readonly) NSUInteger uploadPendingItemsCount;

+ (instancetype)shared;

- (void)startCameraUploadIfPossible;
- (void)startVideoUploadIfPossible;

- (void)uploadNextForAsset:(PHAsset *)asset;

- (void)disableCameraUpload;
- (void)disableVideoUpload;

@end

NS_ASSUME_NONNULL_END
