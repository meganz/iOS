
#import <Foundation/Foundation.h>
#import "CameraUploadRecordManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface CameraUploadCompletionManager : NSObject

+ (instancetype)shared;

- (void)handleCompletedTransferWithLocalIdentifier:(NSString *)localIdentifier token:(NSData *)token;
- (void)handleChunkUploadTask:(NSURLSessionTask *)task;

- (void)finishUploadForLocalIdentifier:(NSString *)localIdentifier status:(CameraAssetUploadStatus)status;

@end

NS_ASSUME_NONNULL_END
