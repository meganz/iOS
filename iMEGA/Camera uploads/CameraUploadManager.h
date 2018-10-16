
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CameraUploadManager : NSObject

+ (instancetype)shared;

- (void)startUploading;

@end

NS_ASSUME_NONNULL_END
