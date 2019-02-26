
#import "MEGAOperation.h"
#import "TransferSessionManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface RestoreUploadTaskOperation : MEGAOperation

- (instancetype)initWithSession:(NSURLSession *)session completion:(RestoreSessionCompletionHandler)completion;

@end

NS_ASSUME_NONNULL_END
