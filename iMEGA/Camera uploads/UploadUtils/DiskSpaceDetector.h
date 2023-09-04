#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DiskSpaceDetector : NSObject

@property (nonatomic, readonly, getter=isDiskFullForPhotos) BOOL diskIsFullForPhotos;
@property (nonatomic, readonly, getter=isDiskFullForVideos) BOOL diskIsFullForVideos;

- (void)startDetectingPhotoUpload;
- (void)startDetectingVideoUpload;

- (void)stopDetectingPhotoUpload;
- (void)stopDetectingVideoUpload;

@end

NS_ASSUME_NONNULL_END
