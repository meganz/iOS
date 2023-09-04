#import <Foundation/Foundation.h>
#import "PhotoUploadOperation.h"
#import "VideoUploadOperation.h"

NS_ASSUME_NONNULL_BEGIN

@class MOAssetUploadRecord;

@interface UploadOperationFactory : NSObject

+ (nullable CameraUploadOperation *)operationForUploadRecord:(MOAssetUploadRecord *)uploadRecord parentNode:(MEGANode *)node error:(NSError *__autoreleasing  _Nullable *)error;

@end

NS_ASSUME_NONNULL_END
