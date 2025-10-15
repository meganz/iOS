#import <Foundation/Foundation.h>
#import "TransferSessionManager.h"

@class CameraUploadTransferProgressOCRepository;

NS_ASSUME_NONNULL_BEGIN

@interface TransferSessionTaskDelegate : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

- (instancetype)initWithCompletionHandler:(UploadCompletionHandler)completion;
- (instancetype)initWithCompletionHandler:(UploadCompletionHandler)completion transferProgressRepository:(nullable CameraUploadTransferProgressOCRepository *)transferProgressRepository;

@end

NS_ASSUME_NONNULL_END
