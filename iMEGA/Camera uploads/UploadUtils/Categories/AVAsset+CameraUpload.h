#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVAsset (CameraUpload)

@property (nonatomic, readonly) CGSize mnz_dimensions;
@property (nonatomic, readonly) BOOL mnz_containsHEVCCodec;

@end

NS_ASSUME_NONNULL_END
