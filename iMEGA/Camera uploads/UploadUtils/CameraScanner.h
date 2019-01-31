
#import <Foundation/Foundation.h>
@import Photos;

NS_ASSUME_NONNULL_BEGIN

@interface CameraScanner : NSObject

- (void)scanMediaTypes:(NSArray<NSNumber *> *)mediaTypes completion:(nullable void (^)(void))completion;

- (void)observePhotoLibraryChanges;
- (void)unobservePhotoLibraryChanges;

@end

NS_ASSUME_NONNULL_END
