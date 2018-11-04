
#import <Foundation/Foundation.h>
#import "TransferSessionManager.h"

NS_ASSUME_NONNULL_BEGIN

@class TransferSessionManager;

@interface TransferSessionTaskDelegate : NSObject <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate>

- (instancetype)initWithCompletionHandler:(UploadCompletionHandler)completion;

@end

NS_ASSUME_NONNULL_END
