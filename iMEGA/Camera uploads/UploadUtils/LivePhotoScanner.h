#import <Foundation/Foundation.h>
@import Photos;

NS_ASSUME_NONNULL_BEGIN

@interface LivePhotoScanner : NSObject

- (void)scanLivePhotosInAssets:(NSArray<PHAsset *> *)assets;

- (BOOL)scanLivePhotosWithError:(NSError * _Nullable __autoreleasing * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
