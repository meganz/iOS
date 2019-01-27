
#import <Foundation/Foundation.h>
#import "MOAssetUploadRecord+CoreDataClass.h"
@import Photos;

NS_ASSUME_NONNULL_BEGIN

extern NSString * const CameraAssetUploadStatusNotStarted;
extern NSString * const CameraAssetUploadStatusQueuedUp;
extern NSString * const CameraAssetUploadStatusProcessing;
extern NSString * const CameraAssetUploadStatusUploading;
extern NSString * const CameraAssetUploadStatusFailed;
extern NSString * const CameraAssetUploadStatusDone;

@class PHAsset, PHFetchResult;

@interface CameraUploadRecordManager : NSObject

+ (instancetype)shared;

#pragma mark - fetch records

- (NSArray<MOAssetUploadRecord *> *)fetchToBeUploadedRecordsWithLimit:(NSInteger)fetchLimit mediaType:(PHAssetMediaType)mediaType error:(NSError * _Nullable __autoreleasing * _Nullable)error;

- (NSArray<MOAssetUploadRecord *> *)fetchAllRecords:(NSError * _Nullable __autoreleasing * _Nullable)error;

- (NSUInteger)pendingRecordsCountByMediaTypes:(NSArray <NSNumber *> *)mediaTypes error:(NSError *__autoreleasing  _Nullable *)error;

- (NSArray<MOAssetUploadRecord *> *)fetchRecordsByStatuses:(NSArray<NSString *> *)statuses error:(NSError *__autoreleasing  _Nullable *)error;

#pragma mark - save records

- (BOOL)saveChangesIfNeeded:(NSError * _Nullable __autoreleasing * _Nullable)error;

- (BOOL)initialSaveWithAssetFetchResult:(PHFetchResult *)result error:(NSError * _Nullable __autoreleasing * _Nullable)error;

- (BOOL)saveAssets:(NSArray<PHAsset *> *)assets error:(NSError * _Nullable __autoreleasing * _Nullable)error;

- (BOOL)saveAsset:(PHAsset *)asset mediaSubtypedLocalIdentifier:(NSString *)identifier error:(NSError * _Nullable __autoreleasing * _Nullable)error;

#pragma mark - update records

- (BOOL)updateRecordOfLocalIdentifier:(NSString *)identifier withStatus:(NSString *)status error:(NSError * _Nullable __autoreleasing * _Nullable)error;

- (BOOL)updateRecord:(MOAssetUploadRecord *)record withStatus:(NSString *)status error:(NSError * _Nullable __autoreleasing * _Nullable)error;

#pragma mark - delete records

- (BOOL)deleteRecord:(MOAssetUploadRecord *)record error:(NSError * _Nullable __autoreleasing * _Nullable)error;

- (BOOL)deleteRecordsByLocalIdentifiers:(NSArray<NSString *> *)identifiers error:(NSError * _Nullable __autoreleasing * _Nullable)error;

#pragma mark - upload error records management

- (BOOL)clearErrorRecordsPerLaunchWithError:(NSError * _Nullable __autoreleasing * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
