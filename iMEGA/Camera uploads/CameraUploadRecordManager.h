
#import <Foundation/Foundation.h>
#import "MOAssetUploadRecord+CoreDataClass.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString * const uploadStatusNotStarted;
extern NSString * const uploadStatusQueuedUp;
extern NSString * const uploadStatusProcessing;
extern NSString * const uploadStatusUploading;
extern NSString * const uploadStatusFailed;
extern NSString * const uploadStatusDone;

@class PHAsset, PHFetchResult;

@interface CameraUploadRecordManager : NSObject

+ (instancetype)shared;

- (BOOL)saveChangesIfNeeded:(NSError * _Nullable __autoreleasing * _Nullable)error;

- (nullable MOAssetUploadRecord *)fetchAssetUploadRecordByLocalIdentifier:(NSString *)identifier error:(NSError * _Nullable __autoreleasing * _Nullable)error;
- (NSArray<MOAssetUploadRecord *> *)fetchNonUploadedRecordsWithLimit:(NSInteger)fetchLimit error:(NSError * _Nullable __autoreleasing * _Nullable)error;
- (NSArray<MOAssetUploadRecord *> *)fetchAllAssetUploadRecords:(NSError * _Nullable __autoreleasing * _Nullable)error;


- (BOOL)saveAssetFetchResult:(PHFetchResult *)result error:(NSError * _Nullable __autoreleasing * _Nullable)error;
- (BOOL)saveAssets:(NSArray<PHAsset *> *)assets error:(NSError * _Nullable __autoreleasing * _Nullable)error;

- (BOOL)updateStatus:(NSString *)status forLocalIdentifier:(NSString *)identifier error:(NSError * _Nullable __autoreleasing * _Nullable)error;
- (BOOL)updateStatus:(NSString *)status forRecord:(MOAssetUploadRecord *)record error:(NSError * _Nullable __autoreleasing * _Nullable)error;

- (BOOL)deleteRecordsByLocalIdentifiers:(NSArray<NSString *> *)identifiers error:(NSError * _Nullable __autoreleasing * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
