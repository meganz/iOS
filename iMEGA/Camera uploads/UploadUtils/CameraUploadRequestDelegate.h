#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^CameraUploadRequestCompletion)(MEGARequest *request, MEGAError * error);

@interface CameraUploadRequestDelegate : NSObject <MEGARequestDelegate>


/**
 Create a MEGA request delegate for camera upload

 @param completion is a `CameraUploadRequestCompletion` type block for callback when request completes
 @warning the completion block will be called on any background thread
 */
- (instancetype)initWithCompletion:(CameraUploadRequestCompletion)completion;

@end

NS_ASSUME_NONNULL_END
