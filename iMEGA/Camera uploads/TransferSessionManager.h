
#import <Foundation/Foundation.h>

extern NSString * const photoTransferSessionId;
extern NSString * const videoTransferSessionId;

NS_ASSUME_NONNULL_BEGIN

typedef void (^UploadCompletionHandler)(NSData  * _Nullable token, NSError * _Nullable error);

@interface TransferSessionManager : NSObject

+ (instancetype)shared;

@property (strong, nonatomic) NSURLSession *photoSession;
@property (strong, nonatomic) NSURLSession *videoSession;
@property (copy, nonatomic) void (^photoSessionCompletion)(void);
@property (copy, nonatomic) void (^videoSessionCompletion)(void);

- (void)restorePhotoSessionIfNeeded;
- (void)restoreVideoSessionIfNeeded;

- (NSURLSessionUploadTask *)photoUploadTaskWithURL:(NSURL *)requestURL fromFile:(NSURL *)fileURL completion:(UploadCompletionHandler)completion;
- (NSURLSessionUploadTask *)videoUploadTaskWithURL:(NSURL *)requestURL fromFile:(NSURL *)fileURL completion:(UploadCompletionHandler)completion;

@end

NS_ASSUME_NONNULL_END
