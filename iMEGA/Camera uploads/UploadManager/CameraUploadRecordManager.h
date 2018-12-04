
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

- (BOOL)saveChangesIfNeeded:(NSError * _Nullable __autoreleasing * _Nullable)error;


- (nullable MOAssetUploadRecord *)fetchAssetUploadRecordByLocalIdentifier:(NSString *)identifier error:(NSError * _Nullable __autoreleasing * _Nullable)error;

- (NSArray<MOAssetUploadRecord *> *)fetchNonUploadedRecordsWithLimit:(NSInteger)fetchLimit mediaType:(PHAssetMediaType)mediaType error:(NSError * _Nullable __autoreleasing * _Nullable)error;

- (NSArray<MOAssetUploadRecord *> *)fetchAllAssetUploadRecords:(NSError * _Nullable __autoreleasing * _Nullable)error;

- (NSArray<MOAssetUploadRecord *> *)fetchAllPendingUploadRecordsInMediaTypes:(NSArray <NSNumber *> *)mediaTypes error:(NSError *__autoreleasing  _Nullable *)error;


- (BOOL)saveAssetFetchResult:(PHFetchResult *)result error:(NSError * _Nullable __autoreleasing * _Nullable)error;

- (BOOL)saveAssets:(NSArray<PHAsset *> *)assets error:(NSError * _Nullable __autoreleasing * _Nullable)error;


- (BOOL)updateStatus:(NSString *)status forLocalIdentifier:(NSString *)identifier error:(NSError * _Nullable __autoreleasing * _Nullable)error;

- (BOOL)updateStatus:(NSString *)status forRecord:(MOAssetUploadRecord *)record error:(NSError * _Nullable __autoreleasing * _Nullable)error;


- (BOOL)deleteRecordsByLocalIdentifiers:(NSArray<NSString *> *)identifiers error:(NSError * _Nullable __autoreleasing * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
