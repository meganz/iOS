
#import <Foundation/Foundation.h>
#import "MOAssetUploadRecord+CoreDataClass.h"
#import "AssetUploadStatus.h"
#import "LocalFileNameCoordinator.h"
@import Photos;

NS_ASSUME_NONNULL_BEGIN

@class PHAsset, PHFetchResult;

@interface CameraUploadRecordManager : NSObject

@property (readonly) LocalFileNameCoordinator *fileNameCoordinator;

+ (instancetype)shared;

- (void)resetDataContext;

#pragma mark - fetch records

- (NSArray<MOAssetUploadRecord *> *)fetchRecordsToUploadByStatuses:(NSArray<NSNumber *> *)statuses fetchLimit:(NSInteger)fetchLimit mediaType:(PHAssetMediaType)mediaType error:(NSError * _Nullable __autoreleasing * _Nullable)error;

- (NSArray<MOAssetUploadRecord *> *)fetchAllUploadRecords:(NSError * _Nullable __autoreleasing * _Nullable)error;

- (NSUInteger)pendingUploadRecordsCountByMediaTypes:(NSArray <NSNumber *> *)mediaTypes error:(NSError *__autoreleasing  _Nullable *)error;

- (NSArray<MOAssetUploadRecord *> *)fetchAllUploadRecordsByStatuses:(NSArray<NSNumber *> *)statuses error:(NSError *__autoreleasing  _Nullable *)error;

#pragma mark - save records

- (BOOL)saveChangesIfNeededWithError:(NSError * _Nullable __autoreleasing * _Nullable)error;

- (BOOL)initialSaveWithAssetFetchResult:(PHFetchResult *)result error:(NSError * _Nullable __autoreleasing * _Nullable)error;

- (BOOL)saveAssets:(NSArray<PHAsset *> *)assets error:(NSError * _Nullable __autoreleasing * _Nullable)error;

- (BOOL)saveAsset:(PHAsset *)asset mediaSubtypedLocalIdentifier:(NSString *)identifier error:(NSError * _Nullable __autoreleasing * _Nullable)error;

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
