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
NSString * const uploadStatusQueuedUp = @"QueuedUp";
NSString * const uploadStatusProcessing = @"Processing";
NSString * const uploadStatusUploading = @"Uploading";
NSString * const uploadStatusFailed = @"Failed";
NSString * const uploadStatusDone = @"Done";

@interface AssetUploadRecordCoreDataManager ()

@property (strong, nonatomic) NSManagedObjectContext *privateQueueContext;

@end

@implementation AssetUploadRecordCoreDataManager

+ (instancetype)shared {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _privateQueueContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        _privateQueueContext.persistentStoreCoordinator = [MEGAStore shareInstance].persistentStoreCoordinator;
    }
    
    return self;
}

- (BOOL)saveChangesIfNeeded:(NSError *__autoreleasing  _Nullable *)error {
    NSError *coreDataError = nil;
    if (self.privateQueueContext.hasChanges) {
        [self.privateQueueContext save:&coreDataError];
    }
    
    if (error != NULL) {
        *error = coreDataError;
    }
    
    return coreDataError == nil;
}

#pragma mark - fetch assets

- (MOAssetUploadRecord *)fetchAssetUploadRecordByLocalIdentifier:(NSString *)identifier error:(NSError *__autoreleasing  _Nullable *)error {
    __block MOAssetUploadRecord *record = nil;
    __block NSError *coreDataError = nil;
    [self.privateQueueContext performBlockAndWait:^{
        NSFetchRequest *request = MOAssetUploadRecord.fetchRequest;
        request.predicate = [NSPredicate predicateWithFormat:@"localIdentifier == %@", identifier];
        record = [[self.privateQueueContext executeFetchRequest:request error:&coreDataError] firstObject];
    }];
    
    if (error != NULL) {
        *error = coreDataError;
    }
    
    return record;
}

- (NSArray<MOAssetUploadRecord *> *)fetchNonUploadedRecordsWithLimit:(NSInteger)fetchLimit error:(NSError *__autoreleasing  _Nullable *)error {
    __block NSArray<MOAssetUploadRecord *> *records = @[];
    __block NSError *coreDataError = nil;
    [self.privateQueueContext performBlockAndWait:^{
        NSFetchRequest *request = MOAssetUploadRecord.fetchRequest;
        request.fetchLimit = fetchLimit;
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"modificationDate" ascending:NO]];
        request.predicate = [NSPredicate predicateWithFormat:@"status IN %@", @[uploadStatusNotStarted, uploadStatusFailed, uploadStatusProcessing]];
        records = [self.privateQueueContext executeFetchRequest:request error:&coreDataError];
    }];
    
    if (error != NULL) {
        *error = coreDataError;
    }
    
    return records;
}

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

#pragma mark - save assets

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

#pragma mark - update records

- (BOOL)updateStatus:(NSString *)status forLocalIdentifier:(NSString *)identifier error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    __block NSError *coreDataError = nil;
    [self.privateQueueContext performBlockAndWait:^{
        NSFetchRequest *request = MOAssetUploadRecord.fetchRequest;
        request.predicate = [NSPredicate predicateWithFormat:@"localIdentifier == %@", identifier];
        MOAssetUploadRecord *record = [[self.privateQueueContext executeFetchRequest:request error:&coreDataError] firstObject];
        if (record && ![record.status isEqualToString:status]) {
            record.status = status;
            [self.privateQueueContext save:&coreDataError];
        }
    }];
    
    if (error != NULL) {
        *error = coreDataError;
    }
    
    return coreDataError == nil;
}

- (BOOL)updateStatus:(NSString *)status forRecord:(MOAssetUploadRecord *)record error:(NSError *__autoreleasing  _Nullable *)error {
    if ([record.status isEqualToString:status]) {
        return YES;
    }
    
    __block NSError *coreDataError = nil;
    [self.privateQueueContext performBlockAndWait:^{
        record.status = status;
        [self.privateQueueContext save:&coreDataError];
    }];
    
    if (error != NULL) {
        *error = coreDataError;
    }
    
    return coreDataError == nil;
}

#pragma mark - delete records

- (BOOL)deleteRecordsByLocalIdentifiers:(NSArray<NSString *> *)identifiers error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    __block NSError *coreDataError = nil;
    if (identifiers.count > 0) {
        [self.privateQueueContext performBlockAndWait:^{
            NSFetchRequest *request = MOAssetUploadRecord.fetchRequest;
            request.predicate = [NSPredicate predicateWithFormat:@"localIdentifier IN %@", identifiers];
            NSBatchDeleteRequest *deleteRequest = [[NSBatchDeleteRequest alloc] initWithFetchRequest:request];
            [self.privateQueueContext executeRequest:deleteRequest error:&coreDataError];
            
        }];
    }
    
    if (error != NULL) {
        *error = coreDataError;
    }
    
    return coreDataError == nil;
}

#pragma mark - helper methods

- (MOAssetUploadRecord *)createUploadStatusFromAsset:(PHAsset *)asset {
    MOAssetUploadRecord *record = [NSEntityDescription insertNewObjectForEntityForName:@"AssetUploadRecord" inManagedObjectContext:self.privateQueueContext];
    record.localIdentifier = asset.localIdentifier;
    record.status = uploadStatusNotStarted;
    record.modificationDate = asset.modificationDate;
    return record;
}

@end
