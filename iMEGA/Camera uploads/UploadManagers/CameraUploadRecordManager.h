
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

#pragma mark - fetch records

- (CameraAssetUploadStatus)uploadStatusForIdentifier:(NSString *)identifier;

- (NSArray<MOAssetUploadRecord *> *)fetchUploadRecordsByIdentifier:(NSString *)identifier shouldPrefetchErrorRecords:(BOOL)prefetchErrorRecords error:(NSError *__autoreleasing  _Nullable *)error;

- (NSArray<MOAssetUploadRecord *> *)queueUpUploadRecordsByStatuses:(NSArray<NSNumber *> *)statuses fetchLimit:(NSUInteger)fetchLimit mediaType:(PHAssetMediaType)mediaType error:(NSError * _Nullable __autoreleasing * _Nullable)error;

- (NSArray<MOAssetUploadRecord *> *)fetchAllUploadRecords:(NSError * _Nullable __autoreleasing * _Nullable)error;

- (NSArray<MOAssetUploadRecord *> *)fetchUploadRecordsByStatuses:(NSArray<NSNumber *> *)statuses error:(NSError *__autoreleasing  _Nullable *)error;

#pragma mark - fetch records by media types

- (NSArray<MOAssetUploadRecord *> *)fetchUploadRecordsByMediaTypes:(NSArray<NSNumber *> *)mediaTypes includeAdditionalMediaSubtypes:(BOOL)includeAdditionalMediaSubtypes error:(NSError * _Nullable __autoreleasing *)error;

- (NSArray<MOAssetUploadRecord *> *)fetchUploadRecordsByMediaTypes:(NSArray<NSNumber *> *)mediaTypes mediaSubtypes:(PHAssetMediaSubtype)subtypes includeAdditionalMediaSubtypes:(BOOL)includeAdditionalMediaSubtypes error:(NSError * _Nullable __autoreleasing *)error;

- (NSArray<MOAssetUploadRecord *> *)fetchUploadRecordsByMediaTypes:(NSArray<NSNumber *> *)mediaTypes additionalMediaSubtypes:(PHAssetMediaSubtype)mediaSubtypes error:(NSError *__autoreleasing  _Nullable *)error;

#pragma mark - fetch upload counts

- (NSUInteger)uploadDoneRecordsCountByMediaTypes:(NSArray<NSNumber *> *)mediaTypes error:(NSError * _Nullable __autoreleasing *)error;

- (NSUInteger)uploadRecordsCountByMediaTypes:(NSArray<NSNumber *> *)mediaTypes error:(NSError * _Nullable __autoreleasing *)error;

- (NSUInteger)pendingRecordsCountByMediaTypes:(NSArray <NSNumber *> *)mediaTypes error:(NSError *__autoreleasing  _Nullable *)error;

- (NSUInteger)uploadingRecordsCountWithError:(NSError *__autoreleasing  _Nullable *)error;

#pragma mark - save records

- (BOOL)saveChangesIfNeededWithError:(NSError * _Nullable __autoreleasing * _Nullable)error;

- (BOOL)saveInitialUploadRecordsByAssetFetchResult:(PHFetchResult *)result error:(NSError * _Nullable __autoreleasing * _Nullable)error;

#pragma mark - create records

- (void)createUploadRecordsIfNeededByAssets:(NSArray<PHAsset *> *)assets;

- (void)createAdditionalRecordsIfNeededForRecords:(NSArray<MOAssetUploadRecord *> *)uploadRecords withMediaSubtype:(PHAssetMediaSubtype)subtype;

#pragma mark - update records

- (BOOL)updateUploadRecordByLocalIdentifier:(NSString *)identifier withStatus:(CameraAssetUploadStatus)status error:(NSError * _Nullable __autoreleasing * _Nullable)error;

- (BOOL)updateUploadRecord:(MOAssetUploadRecord *)record withStatus:(CameraAssetUploadStatus)status error:(NSError * _Nullable __autoreleasing * _Nullable)error;

#pragma mark - delete records

- (BOOL)deleteAllUploadRecordsWithError:(NSError * _Nullable __autoreleasing * _Nullable)error;

- (BOOL)deleteUploadRecord:(MOAssetUploadRecord *)record error:(NSError * _Nullable __autoreleasing * _Nullable)error;

- (BOOL)deleteUploadRecordsByLocalIdentifiers:(NSArray<NSString *> *)identifiers error:(NSError * _Nullable __autoreleasing * _Nullable)error;

#pragma mark - upload error records management

- (BOOL)deleteAllErrorRecordsPerLaunchWithError:(NSError * _Nullable __autoreleasing * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
