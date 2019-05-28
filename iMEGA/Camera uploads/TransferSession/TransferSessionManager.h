
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^UploadCompletionHandler)(NSData  * _Nullable token, NSError * _Nullable error);
typedef void (^RestoreSessionCompletionHandler)(NSArray<NSURLSessionUploadTask *> * _Nonnull uploadTasks);

@interface TransferSessionManager : NSObject

+ (instancetype)shared;

- (void)invalidateAndCancelVideoSessions;
- (void)invalidateAndCancelPhotoSessions;

- (void)restorePhotoSessionsWithCompletion:(nullable RestoreSessionCompletionHandler)completion;
- (void)restoreVideoSessionsWithCompletion:(nullable RestoreSessionCompletionHandler)completion;

- (void)saveSessionCompletion:(void (^)(void))completion forIdentifier:(NSString *)identifier;

- (NSURLSessionUploadTask *)photoUploadTaskWithURL:(NSURL *)requestURL fromFile:(NSURL *)fileURL completion:(nullable UploadCompletionHandler)completion;

- (NSURLSessionUploadTask *)videoUploadTaskWithURL:(NSURL *)requestURL fromFile:(NSURL *)fileURL completion:(nullable UploadCompletionHandler)completion;

- (void)finishEventsForBackgroundURLSession:(NSURLSession *)session;

@end

NS_ASSUME_NONNULL_END
