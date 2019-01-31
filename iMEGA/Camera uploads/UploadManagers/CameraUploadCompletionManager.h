
#import <Foundation/Foundation.h>
#import "AssetUploadInfo.h"
#import "MEGASdkManager.h"
#import "CameraUploadRecordManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface CameraUploadCompletionManager : NSObject

+ (instancetype)shared;

- (void)handleCompletedTransferWithLocalIdentifier:(NSString *)localIdentifier token:(NSData *)token;

- (void)finishUploadForLocalIdentifier:(NSString *)localIdentifier status:(NSString *)status;

- (void)waitUnitlAllUploadsAreFinished;

@end

NS_ASSUME_NONNULL_END
