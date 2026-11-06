#import <Foundation/Foundation.h>
#import "CameraUploadRecordManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface CameraUploadCompletionManager : NSObject

+ (instancetype)shared;

- (void)handleCompletedTransferWithLocalIdentifier:(NSString *)localIdentifier token:(NSData *)token;

/// Finishes the upload of a file after its background transfer ended. A failure is reported at the transfer step.
- (void)finishTransferForLocalIdentifier:(NSString *)localIdentifier status:(CameraAssetUploadStatus)status error:(nullable NSError *)error;

@end

NS_ASSUME_NONNULL_END
