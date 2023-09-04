#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MOAssetUploadRecord;

@interface LocalFileNameGenerator : NSObject

- (instancetype)initWithBackgroundContext:(NSManagedObjectContext *)context;

/**
 Generate a local unique file name for a given asset upload record and proposed file name. Under the hood, we have a serial queue to fetch local upload file name records from local core data db, generate local unique file name base on a binary search algorithm, and save the new local unique file name to local core data db.
 
 @discussion This is an on-demand pattern to resovle local unique file name issue. An unique name won't be generated unless an asset starts its upload process.
 
 This method is designed for thread safe to make sure it generates unique local file name.

 @param record asset upload record with MOAssetUploadRecord type
 @param originalFileName the original file name to search and compare with
 @return a local unique file name by appending "_%d" after the originalFileName. the originalFileName will be returned directly if there is no same file names exist.
 */
- (NSString *)generateUniqueLocalFileNameForUploadRecord:(MOAssetUploadRecord *)record withOriginalFileName:(NSString *)originalFileName;

@end

NS_ASSUME_NONNULL_END
