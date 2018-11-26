
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class PHAsset;

@interface CameraUploadManager : NSObject

+ (instancetype)shared;

- (void)startCameraUploadIfPossible;
- (void)startVideoUploadIfPossible;

- (void)uploadNextForAsset:(PHAsset *)asset;

- (void)disableCameraUpload;
- (void)disableVideoUpload;

@end

NS_ASSUME_NONNULL_END
