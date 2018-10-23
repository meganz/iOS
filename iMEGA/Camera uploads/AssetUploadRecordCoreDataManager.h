//
//  AssetUploadRecordCoreDataManager.h
//  MEGA
//
//  Created by Simon Wang on 8/10/18.
//  Copyright © 2018 MEGA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MOAssetUploadRecord+CoreDataClass.h"

extern NSString * const uploadStatusNotStarted;
extern NSString * const uploadStatusProcessing;
extern NSString * const uploadStatusUploading;
extern NSString * const uploadStatusFailed;
extern NSString * const uploadStatusDone;

NS_ASSUME_NONNULL_BEGIN

@class PHAsset, PHFetchResult;

@interface AssetUploadRecordCoreDataManager : NSObject

+ (instancetype)shared;

- (NSArray<MOAssetUploadRecord *> *)fetchNonUploadedRecordsWithLimit:(NSInteger)fetchLimit error:(NSError * _Nullable __autoreleasing * _Nullable)error;

- (NSArray<MOAssetUploadRecord *> *)fetchAllAssetUploadRecords:(NSError * _Nullable __autoreleasing * _Nullable)error;

- (BOOL)saveAssetFetchResult:(PHFetchResult *)result error:(NSError * _Nullable __autoreleasing * _Nullable)error;

- (BOOL)saveAssets:(NSArray<PHAsset *> *)assets error:(NSError * _Nullable __autoreleasing * _Nullable)error;

- (BOOL)updateStatus:(NSString *)status forLocalIdentifier:(NSString *)identifier error:(NSError * _Nullable __autoreleasing * _Nullable)error;

- (BOOL)deleteRecordsByLocalIdentifiers:(NSArray<NSString *> *)identifiers error:(NSError * _Nullable __autoreleasing * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
