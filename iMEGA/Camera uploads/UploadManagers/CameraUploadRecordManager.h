#import <Foundation/Foundation.h>
#import "MOAssetUploadRecord+CoreDataClass.h"
#import "AssetUploadStatus.h"
#import "LocalFileNameGenerator.h"
@import Photos;

NS_ASSUME_NONNULL_BEGIN

@class PHAsset, PHFetchResult, CameraUploadRetryScheduler;

@interface CameraUploadRecordManager : NSObject

@property (readonly) LocalFileNameGenerator *fileNameCoordinator;
@property (readonly) NSManagedObjectContext *backgroundContext;

+ (instancetype)shared;

- (void)resetDataContext;

#pragma mark - access properties of record

- (nullable NSString *)savedIdentifierInRecord:(MOAssetUploadRecord *)record;

#pragma mark - memory management

- (void)refaultObject:(NSManagedObject *)object;

#pragma mark - fetch records

- (NSArray<MOAssetUploadRecord *> *)fetchUploadRecordsByIdentifier:(NSString *)identifier shouldPrefetchErrorRecords:(BOOL)prefetchErrorRecords error:(NSError *__autoreleasing  _Nullable *)error;

/// Marks the next record to upload as queued up, choosing between records that never failed since login and records that did.
/// @param retryScheduler Decides when a previously failed record is served instead of one that never failed.
/// @param concurrentCount The upload queue's maximum concurrent operation count.
- (nullable MOAssetUploadRecord *)queueUpNextUploadRecordByStatuses:(NSArray<NSNumber *> *)statuses mediaType:(PHAssetMediaType)mediaType retryScheduler:(CameraUploadRetryScheduler *)retryScheduler concurrentCount:(NSInteger)concurrentCount error:(NSError * _Nullable __autoreleasing * _Nullable)error;

/// Lane of records that never failed since login. Exposed for unit testing.
@property (class, nonatomic, readonly) NSPredicate *neverFailedRecordsPredicate;
/// Lane of records that failed in an earlier launch but not in this one. Exposed for unit testing.
@property (class, nonatomic, readonly) NSPredicate *failedBeforeThisLaunchRecordsPredicate;
/// Lane of records that failed in this launch. Exposed for unit testing.
@property (class, nonatomic, readonly) NSPredicate *failedInThisLaunchRecordsPredicate;
/// Order of the failed-in-this-launch lane: least failed first, then newest first. Exposed for unit testing.
@property (class, nonatomic, readonly) NSArray<NSSortDescriptor *> *failedInThisLaunchRecordsSortDescriptors;

- (NSArray<MOAssetUploadRecord *> *)fetchUploadRecordsByStatuses:(NSArray<NSNumber *> *)statuses error:(NSError *__autoreleasing  _Nullable *)error;

#pragma mark - fetch records by media types

- (NSArray<MOAssetUploadRecord *> *)fetchUploadRecordsByMediaTypes:(NSArray<NSNumber *> *)mediaTypes statuses:(NSArray<NSNumber *> *)statuses error:(NSError * _Nullable __autoreleasing *)error;

- (NSArray<MOAssetUploadRecord *> *)fetchUploadRecordsByMediaTypes:(NSArray<NSNumber *> *)mediaTypes includeAdditionalMediaSubtypes:(BOOL)includeAdditionalMediaSubtypes error:(NSError * _Nullable __autoreleasing *)error;

- (NSArray<MOAssetUploadRecord *> *)fetchUploadRecordsByMediaTypes:(NSArray<NSNumber *> *)mediaTypes additionalMediaSubtypes:(PHAssetMediaSubtype)mediaSubtypes error:(NSError *__autoreleasing  _Nullable *)error;

#pragma mark - fetch upload counts

- (NSUInteger)finishedRecordsCountByMediaTypes:(NSArray<NSNumber *> *)mediaTypes error:(NSError * _Nullable __autoreleasing *)error;

- (NSUInteger)totalRecordsCountByMediaTypes:(NSArray<NSNumber *> *)mediaTypes includeUploadErrorRecords:(BOOL)includeUploadErrorRecords error:(NSError * _Nullable __autoreleasing *)error;

- (NSUInteger)pendingRecordsCountByMediaTypes:(NSArray<NSNumber *> *)mediaTypes error:(NSError *__autoreleasing  _Nullable *)error;

- (NSUInteger)uploadingRecordsCountWithError:(NSError *__autoreleasing  _Nullable *)error;

- (NSUInteger)pendingForUploadingRecordsCountByMediaTypes:(NSArray<NSNumber *> *)mediaTypes error:(NSError *__autoreleasing  _Nullable *)error;

#pragma mark - save records

- (BOOL)saveChangesIfNeededWithError:(NSError * _Nullable __autoreleasing * _Nullable)error;

#pragma mark - update records

- (BOOL)updateUploadRecord:(MOAssetUploadRecord *)record withStatus:(CameraAssetUploadStatus)status error:(NSError * _Nullable __autoreleasing * _Nullable)error;

#pragma mark - delete records

- (BOOL)deleteUploadRecord:(MOAssetUploadRecord *)record error:(NSError * _Nullable __autoreleasing * _Nullable)error;

/// One-time cleanup for "Upload Only New Photos": deletes pending records (everything except the
/// completed and currently in-flight statuses) whose stored capture date is before @c cutoff, so
/// existing CoreData aligns with the scan-time @c creationDate filter. Done / QueuedUp / Processing
/// / Uploading records are preserved. Asynchronous — the record count is unbounded, so the work
/// runs on the background context in bounded batches without blocking the caller; @c completion is
/// invoked on the context's queue with the first error encountered, or nil on success.
- (void)deletePendingRecordsBeforeDate:(NSDate *)cutoff completion:(void (^ _Nullable)(NSError * _Nullable))completion;

/// Synchronous variant of @c deletePendingRecordsBeforeDate:completion: , used by the scanner to drop
/// pre-cutoff pending records before uploads are queued. Returns the number of deleted records.
- (NSUInteger)deletePendingRecordsBeforeDate:(NSDate *)cutoff error:(NSError * _Nullable __autoreleasing * _Nullable)error;

/// The fetch predicate used by @c deletePendingRecordsBeforeDate:completion: . Exposed for unit testing.
+ (NSPredicate *)pendingRecordsToDeletePredicateBeforeDate:(NSDate *)cutoff;

#pragma mark - upload error records management

- (BOOL)deleteAllErrorRecordsPerLaunchWithError:(NSError * _Nullable __autoreleasing * _Nullable)error;

#pragma mark - helper methods

- (NSPredicate *)predicateByFilterAssetUploadRecordError;

@end

NS_ASSUME_NONNULL_END
