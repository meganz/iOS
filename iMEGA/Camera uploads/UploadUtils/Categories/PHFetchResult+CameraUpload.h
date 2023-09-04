#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

@class MOAssetUploadRecord;

@interface PHFetchResult (CameraUpload)

/**
 This method is to find new assets by upload records. We use hash table to compare the identifiers to check if an asset exists in the given upload records.
 
 Because we need to access the properties of MOAssetUploadRecord, you need to call this method within a performBlockAndWait or performBlock method of the corresponding NSManagedObjectContext.
 
 The complexity of this method is O(N), where N means how many assets in the current fetch result.

 @param records the saved upload records
 @return an array of PHAsset object
 */
- (NSArray<PHAsset *> *)findNewAssetsInUploadRecords:(NSArray<MOAssetUploadRecord *> *)records;


- (NSArray<PHAsset *> *)findNewLivePhotoAssetsInUploadRecords:(NSArray<MOAssetUploadRecord *> *)records;

@end

NS_ASSUME_NONNULL_END
