
#import <Foundation/Foundation.h>
@import Photos;

NS_ASSUME_NONNULL_BEGIN

@interface CameraScanner : NSObject

- (void)scanMediaType:(PHAssetMediaType)mediaType completion:(void (^)(void))completion;

@end

NS_ASSUME_NONNULL_END
