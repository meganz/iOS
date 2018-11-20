
#import <Foundation/Foundation.h>
#import "PhotoUploadOperation.h"
#import "VideoUploadOperation.h"

NS_ASSUME_NONNULL_BEGIN

@interface UploadOperationFactory : NSObject

+ (nullable CameraUploadOperation *)operationWithLocalIdentifier:(NSString *)identifier parentNode:(MEGANode *)node;

@end

NS_ASSUME_NONNULL_END
