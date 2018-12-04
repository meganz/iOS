
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^UploadCompletionHandler)(NSData  * _Nullable token, NSError * _Nullable error);

@interface TransferSessionManager : NSObject

+ (instancetype)shared;

- (void)restoreSessionIfNeededByIdentifier:(NSString *)identifier;

- (void)saveSessionCompletion:(void (^)(void))completion forIdentifier:(NSString *)identifier;

- (NSArray<NSURLSessionUploadTask *> *)allRunningUploadTasks;

- (NSURLSessionUploadTask *)photoUploadTaskWithURL:(NSURL *)requestURL fromFile:(NSURL *)fileURL completion:(nullable UploadCompletionHandler)completion;

- (NSURLSessionUploadTask *)videoUploadTaskWithURL:(NSURL *)requestURL fromFile:(NSURL *)fileURL completion:(nullable UploadCompletionHandler)completion;

- (void)didFinishEventsForBackgroundURLSession:(NSURLSession *)session;

@end

NS_ASSUME_NONNULL_END
