
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^CameraUploadRequestCompletion)(MEGARequest *request, MEGAError * error);

@interface CameraUploadRequestDelegate : NSObject <MEGARequestDelegate>

- (instancetype)initWithCompletion:(CameraUploadRequestCompletion)completion;

@end

NS_ASSUME_NONNULL_END
