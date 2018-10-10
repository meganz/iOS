//
//  AssetUploadStatusCoreDataManager.m
//  MEGA
//
//  Created by Simon Wang on 8/10/18.
//  Copyright © 2018 MEGA. All rights reserved.
//

#import "AssetUploadRecordCoreDataManager.h"
#import "MEGAStore.h"
@import Photos;

NSString * const uploadStatusNotStarted = @"NotStarted";
NSString * const uploadStatusDownloading = @"Downloading";
NSString * const uploadStatusProcessing = @"Processing";
NSString * const uploadStatusUploading = @"Uploading";
NSString * const uploadStatusFailed = @"Failed";
NSString * const uploadStatusDone = @"Done";

@interface AssetUploadRecordCoreDataManager ()

@property (strong, nonatomic) NSManagedObjectContext *privateQueueContext;

@end

@implementation AssetUploadRecordCoreDataManager

- (instancetype)init {
    self = [super init];
    if (self) {
        _privateQueueContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        _privateQueueContext.persistentStoreCoordinator = [MEGAStore shareInstance].persistentStoreCoordinator;
    }
    
    return self;
}

#pragma mark - asset upload status core data managing methods

- (NSArray<MOAssetUploadRecord *> *)fetchAllAssetUploadRecords:(NSError * _Nullable __autoreleasing * _Nullable)error {
    __block NSArray<MOAssetUploadRecord *> *records = @[];
    __block NSError *coreDataError = nil;
    [self.privateQueueContext performBlockAndWait:^{
        records = [self.privateQueueContext executeFetchRequest:MOAssetUploadRecord.fetchRequest error:&coreDataError];
    }];
    
    if (error != NULL) {
        *error = coreDataError;
    }
    
    return records;
}

- (BOOL)saveAssetFetchResult:(PHFetchResult<PHAsset *> *)result error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    __block NSError *coreDataError = nil;
    if (result.count > 0) {
        [self.privateQueueContext performBlockAndWait:^{
            for (PHAsset *asset in result) {
                [self createUploadStatusFromAsset:asset];
            }
            
            [self.privateQueueContext save:&coreDataError];
        }];
    }
    
    if (error != NULL) {
        *error = coreDataError;
    }
    
    return coreDataError == nil;
}

- (BOOL)saveAssets:(NSArray<PHAsset *> *)assets error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    __block NSError *coreDataError = nil;
    if (assets.count > 0) {
        [self.privateQueueContext performBlockAndWait:^{
            for (PHAsset *asset in assets) {
                [self createUploadStatusFromAsset:asset];
            }
            
            [self.privateQueueContext save:&coreDataError];
        }];
    }
    
    if (error != NULL) {
        *error = coreDataError;
    }
    
    return coreDataError == nil;
}

- (MOAssetUploadRecord *)createUploadStatusFromAsset:(PHAsset *)asset {
    MOAssetUploadRecord *record = [NSEntityDescription insertNewObjectForEntityForName:@"AssetUploadRecord" inManagedObjectContext:self.privateQueueContext];
    record.localIdentifier = asset.localIdentifier;
    record.status = uploadStatusNotStarted;
    record.creationDate = asset.creationDate;
    return record;
}

@end
