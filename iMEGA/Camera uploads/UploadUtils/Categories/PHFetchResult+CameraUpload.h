
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@class MOAssetUploadRecord;

@interface PHFetchResult (CameraUpload)

/**
 this method is to find new assets by upload records efficiently. We use binary search to compare the identifiers to
 check is an asset is saved to upload record.
 
 Because we need to access the properties of MOAssetUploadRecord, you may want to call this method within a performBlockAndWait or performBlock method of the corresponding NSManagedObjectContext

 @param records the saved upload records
 @return an array of PHAsset object
 */
- (NSArray<PHAsset *> *)findNewAssetsBySortedUploadRecords:(NSArray<MOAssetUploadRecord *> *)records;


- (NSArray<PHAsset *> *)findNewLivePhotoAssetsBySortedUploadRecords:(NSArray<MOAssetUploadRecord *> *)records;

@end

NS_ASSUME_NONNULL_END
