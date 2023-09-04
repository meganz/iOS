#import <Foundation/Foundation.h>
#import "MOAssetUploadRecord+CoreDataClass.h"
#import "AssetUploadStatus.h"
#import "LocalFileNameGenerator.h"
@import Photos;

NS_ASSUME_NONNULL_BEGIN

@class PHAsset, PHFetchResult;

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

- (NSArray<MOAssetUploadRecord *> *)queueUpUploadRecordsByStatuses:(NSArray<NSNumber *> *)statuses fetchLimit:(NSUInteger)fetchLimit mediaType:(PHAssetMediaType)mediaType error:(NSError * _Nullable __autoreleasing * _Nullable)error;

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

#pragma mark - upload error records management

- (BOOL)deleteAllErrorRecordsPerLaunchWithError:(NSError * _Nullable __autoreleasing * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
