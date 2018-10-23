
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CameraUploadManager : NSObject

+ (instancetype)shared;

- (void)startUploading;

- (void)uploadNextPhoto;
- (void)uploadNextPhotoBatch;

@end

NS_ASSUME_NONNULL_END
