
#import "CameraUploadRecordManager.h"
#import "MEGAStore.h"
#import "MOAssetUploadErrorPerLaunch+CoreDataClass.h"
#import "MOAssetUploadErrorPerLogin+CoreDataClass.h"

NSString * const CameraAssetUploadStatusNotStarted = @"NotStarted";
NSString * const CameraAssetUploadStatusQueuedUp = @"QueuedUp";
NSString * const CameraAssetUploadStatusProcessing = @"Processing";
NSString * const CameraAssetUploadStatusUploading = @"Uploading";
NSString * const CameraAssetUploadStatusFailed = @"Failed";
NSString * const CameraAssetUploadStatusDone = @"Done";

static const NSUInteger MaximumUploadRetryPerLaunchCount = 20;
static const NSUInteger MaximumUploadRetryPerLoginCount = 200;

@interface CameraUploadRecordManager ()

@property (strong, nonatomic) NSManagedObjectContext *privateQueueContext;

@end

@implementation CameraUploadRecordManager

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

#pragma mark - fetch records

- (NSArray<MOAssetUploadRecord *> *)fetchRecordByLocalIdentifier:(NSString *)identifier error:(NSError *__autoreleasing  _Nullable *)error {
    NSFetchRequest *request = MOAssetUploadRecord.fetchRequest;
    request.predicate = [NSPredicate predicateWithFormat:@"localIdentifier == %@", identifier];
    [request setRelationshipKeyPathsForPrefetching:@[@"errorPerLaunch", @"errorPerLogin"]];
    return [self fetchRecordsByFetchRequest:request error:error];
}

- (NSArray<MOAssetUploadRecord *> *)fetchToBeUploadedRecordsWithLimit:(NSInteger)fetchLimit mediaType:(PHAssetMediaType)mediaType error:(NSError *__autoreleasing  _Nullable *)error {
    NSFetchRequest *request = MOAssetUploadRecord.fetchRequest;
    request.fetchLimit = fetchLimit;
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(status IN %@) AND (mediaType == %@)", @[CameraAssetUploadStatusNotStarted, CameraAssetUploadStatusFailed], @(mediaType)];
    request.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, [self predicateForAssetUploadRecordError]]];
    [request setRelationshipKeyPathsForPrefetching:@[@"errorPerLaunch", @"errorPerLogin"]];
    return [self fetchRecordsByFetchRequest:request error:error];
}

- (NSArray<MOAssetUploadRecord *> *)fetchAllRecords:(NSError * _Nullable __autoreleasing * _Nullable)error {
    return [self fetchRecordsByFetchRequest:MOAssetUploadRecord.fetchRequest error:error];
}

- (NSUInteger)pendingRecordsCountByMediaTypes:(NSArray<NSNumber *> *)mediaTypes error:(NSError * _Nullable __autoreleasing *)error {
    __block NSUInteger pendingCount = 0;
    __block NSError *coreDataError = nil;
    [self.privateQueueContext performBlockAndWait:^{
        NSFetchRequest *request = MOAssetUploadRecord.fetchRequest;
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(status <> %@) AND (mediaType IN %@)", CameraAssetUploadStatusDone, mediaTypes];
        request.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, [self predicateForAssetUploadRecordError]]];
        pendingCount = [self.privateQueueContext countForFetchRequest:request error:&coreDataError];
    }];
    
    if (error != NULL) {
        *error = coreDataError;
    }
    
    if (coreDataError != nil) {
        pendingCount = 0;
    }
    
    return pendingCount;
}

- (NSArray<MOAssetUploadRecord *> *)fetchRecordsByStatuses:(NSArray<NSString *> *)statuses error:(NSError * _Nullable __autoreleasing *)error {
    NSFetchRequest *request = MOAssetUploadRecord.fetchRequest;
    request.predicate = [NSPredicate predicateWithFormat:@"status IN %@", statuses];
    return [self fetchRecordsByFetchRequest:request error:error];
}

- (NSArray<MOAssetUploadRecord *> *)fetchRecordsByFetchRequest:(NSFetchRequest *)request error:(NSError * _Nullable __autoreleasing *)error {
    __block NSArray<MOAssetUploadRecord *> *records = @[];
    __block NSError *coreDataError = nil;
    [self.privateQueueContext performBlockAndWait:^{
        records = [self.privateQueueContext executeFetchRequest:request error:&coreDataError];
    }];
    
    if (error != NULL) {
        *error = coreDataError;
    }
    
    return records;
}

#pragma mark - save records

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

- (BOOL)saveAssets:(NSArray<PHAsset *> *)assets checkExistence:(BOOL)checkExistence error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    __block NSError *coreDataError = nil;
    if (assets.count > 0) {
        [self.privateQueueContext performBlockAndWait:^{
            for (PHAsset *asset in assets) {
                if (checkExistence) {
                    if ([self fetchRecordByLocalIdentifier:asset.localIdentifier error:nil].count == 0) {
                        [self createUploadStatusFromAsset:asset];
                    }
                } else {
                    [self createUploadStatusFromAsset:asset];
                }
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

- (BOOL)updateRecordOfLocalIdentifier:(NSString *)identifier withStatus:(NSString *)status error:(NSError *__autoreleasing  _Nullable *)error {
    __block NSError *coreDataError = nil;
    NSArray *records = [self fetchRecordByLocalIdentifier:identifier error:&coreDataError];
    for (MOAssetUploadRecord *record in records) {
        [self updateRecord:record withStatus:status error:&coreDataError];
    }

    if (error != NULL) {
        *error = coreDataError;
    }
    
    return coreDataError == nil;
}

- (BOOL)updateRecord:(MOAssetUploadRecord *)record withStatus:(NSString *)status error:(NSError *__autoreleasing  _Nullable *)error {
    __block NSError *coreDataError = nil;
    [self.privateQueueContext performBlockAndWait:^{
        record.status = status;
        if ([status isEqualToString:CameraAssetUploadStatusFailed]) {
            if (record.errorPerLaunch == nil) {
                record.errorPerLaunch = [self createErrorRecordPerLaunchForLocalIdentifier:record.localIdentifier];
            }
            record.errorPerLaunch.errorCount = @(record.errorPerLaunch.errorCount.unsignedIntegerValue + 1);
            
            if (record.errorPerLogin == nil) {
                record.errorPerLogin = [self createErrorRecordPerLoginForLocalIdentifier:record.localIdentifier];
            }
            record.errorPerLogin.errorCount = @(record.errorPerLogin.errorCount.unsignedIntegerValue + 1);
        }
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

#pragma mark - error record management

- (BOOL)clearErrorRecordsPerLaunchWithError:(NSError * _Nullable __autoreleasing * _Nullable)error {
    __block NSError *coreDataError = nil;
    [self.privateQueueContext performBlockAndWait:^{
        NSFetchRequest *request = MOAssetUploadErrorPerLaunch.fetchRequest;
        NSBatchDeleteRequest *deleteRequest = [[NSBatchDeleteRequest alloc] initWithFetchRequest:request];
        [self.privateQueueContext executeRequest:deleteRequest error:&coreDataError];
    }];
    
    if (error != NULL) {
        *error = coreDataError;
    }
    
    return coreDataError == nil;
}

#pragma mark - helper methods

- (void)createUploadStatusFromAsset:(PHAsset *)asset {
    if (asset.localIdentifier.length == 0) {
        return;
    }
    
    MOAssetUploadRecord *record = [NSEntityDescription insertNewObjectForEntityForName:@"AssetUploadRecord" inManagedObjectContext:self.privateQueueContext];
    record.localIdentifier = asset.localIdentifier;
    record.status = CameraAssetUploadStatusNotStarted;
    record.creationDate = asset.creationDate;
    record.mediaType = @(asset.mediaType);
}

- (MOAssetUploadErrorPerLaunch *)createErrorRecordPerLaunchForLocalIdentifier:(NSString *)identifier {
    MOAssetUploadErrorPerLaunch *errorPerLaunch = [NSEntityDescription insertNewObjectForEntityForName:@"AssetUploadErrorPerLaunch" inManagedObjectContext:self.privateQueueContext];
    errorPerLaunch.localIdentifier = identifier;
    errorPerLaunch.errorCount = @(0);
    return errorPerLaunch;
}

- (MOAssetUploadErrorPerLogin *)createErrorRecordPerLoginForLocalIdentifier:(NSString *)identifier {
    MOAssetUploadErrorPerLogin *errorPerLogin = [NSEntityDescription insertNewObjectForEntityForName:@"AssetUploadErrorPerLogin" inManagedObjectContext:self.privateQueueContext];
    errorPerLogin.localIdentifier = identifier;
    errorPerLogin.errorCount = @(0);
    return errorPerLogin;
}

- (NSPredicate *)predicateForAssetUploadRecordError {
    NSPredicate *errorPerLaunch = [NSPredicate predicateWithFormat:@"(errorPerLaunch == %@) OR (errorPerLaunch.errorCount <= %@)", NSNull.null, @(MaximumUploadRetryPerLaunchCount)];
    NSPredicate *errorPerLogin = [NSPredicate predicateWithFormat:@"(errorPerLogin == %@) OR (errorPerLogin.errorCount <= %@)", NSNull.null, @(MaximumUploadRetryPerLoginCount)];
    return [NSCompoundPredicate andPredicateWithSubpredicates:@[errorPerLaunch, errorPerLogin]];
}

@end
