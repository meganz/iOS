
#import <Foundation/Foundation.h>
@import Photos;

NS_ASSUME_NONNULL_BEGIN

@interface LivePhotoScanner : NSObject

- (void)saveInitialLivePhotoRecordsInFetchResult:(PHFetchResult<PHAsset *> *)fetchResult;

- (void)scanLivePhotosInAssets:(NSArray<PHAsset *> *)assets;

- (void)scanLivePhotosInFetchResult:(PHFetchResult<PHAsset *> *)result;

@end

NS_ASSUME_NONNULL_END
