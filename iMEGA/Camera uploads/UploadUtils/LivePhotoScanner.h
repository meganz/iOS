
#import <Foundation/Foundation.h>
@import Photos;

NS_ASSUME_NONNULL_BEGIN

@interface LivePhotoScanner : NSObject

- (void)saveInitialLivePhotoRecordsByFetchResult:(PHFetchResult<PHAsset *> *)fetchResult;

- (void)saveLivePhotoRecordsIfNeededByAssets:(NSArray<PHAsset *> *)assets;

- (void)scanLivePhotosWithCompletion:(nullable void (^)(void))completion;

@end

NS_ASSUME_NONNULL_END
