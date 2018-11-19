
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const photoTransferSessionId;
extern NSString * const videoTransferSessionId;

typedef void (^UploadCompletionHandler)(NSData  * _Nullable token, NSError * _Nullable error);

@interface TransferSessionManager : NSObject

+ (instancetype)shared;

@property (strong, nonatomic) NSURLSession *photoSession;
@property (strong, nonatomic) NSURLSession *videoSession;
@property (copy, nonatomic) void (^photoSessionCompletion)(void);
@property (copy, nonatomic) void (^videoSessionCompletion)(void);

- (void)restorePhotoSessionIfNeeded;
- (void)restoreVideoSessionIfNeeded;

- (NSURLSessionUploadTask *)photoUploadTaskWithURL:(NSURL *)requestURL fromFile:(NSURL *)fileURL completion:(nullable UploadCompletionHandler)completion;
- (NSURLSessionUploadTask *)videoUploadTaskWithURL:(NSURL *)requestURL fromFile:(NSURL *)fileURL completion:(nullable UploadCompletionHandler)completion;

- (void)didFinishEventsForBackgroundURLSession:(NSURLSession *)session;

@end

NS_ASSUME_NONNULL_END
