
#import <Foundation/Foundation.h>
#import "PhotoUploadOperation.h"
#import "VideoUploadOperation.h"

NS_ASSUME_NONNULL_BEGIN

@class MOAssetUploadRecord;

@interface UploadOperationFactory : NSObject

+ (CameraUploadOperation *)operationForUploadRecord:(MOAssetUploadRecord *)uploadRecord parentNode:(MEGANode *)node;

@end

NS_ASSUME_NONNULL_END
