
#import <Foundation/Foundation.h>
@import Photos;

NS_ASSUME_NONNULL_BEGIN

@interface LivePhotoScanner : NSObject

- (BOOL)saveInitialLivePhotoRecordsInFetchResult:(PHFetchResult<PHAsset *> *)fetchResult error:(NSError * _Nullable __autoreleasing * _Nullable)error;

- (void)scanLivePhotosInAssets:(NSArray<PHAsset *> *)assets;

- (BOOL)scanLivePhotosInFetchResult:(PHFetchResult<PHAsset *> *)result error:(NSError * _Nullable __autoreleasing * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
