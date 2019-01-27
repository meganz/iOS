
#import <Foundation/Foundation.h>
#import "PhotoUploadOperation.h"
#import "VideoUploadOperation.h"

NS_ASSUME_NONNULL_BEGIN

@class MOAssetUploadRecord;

@interface UploadOperationFactory : NSObject

+ (CameraUploadOperation *)operationWithUploadRecord:(MOAssetUploadRecord *)uploadRecord parentNode:(MEGANode *)node identifierSeparator:(NSString *)identifierSeparator savedMediaSubtype:(PHAssetMediaSubtype *)savedMediaSubtype;

@end

NS_ASSUME_NONNULL_END
