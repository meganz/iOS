#import "CameraUploadRecordManager.h"
#import "MOAssetUploadErrorPerLaunch+CoreDataClass.h"
#import "MOAssetUploadErrorPerLogin+CoreDataClass.h"
#import "LocalFileNameGenerator.h"
#import "SavedIdentifierParser.h"
#import "NSURL+CameraUpload.h"
#import "MEGACoreDataStack.h"
#import "CoreDataErrorHandler.h"
#import "NSError+CameraUpload.h"

static const NSUInteger MaximumUploadRetryPerLaunchCount = 7;
static const NSUInteger MaximumUploadRetryPerLoginCount = 7 * 77;

@interface CameraUploadRecordManager ()

@property (strong, nonatomic, nullable) NSManagedObjectContext *backgroundContext;
@property (strong, nonatomic) LocalFileNameGenerator *fileNameCoordinator;
@property (strong, nonatomic) dispatch_queue_t serialQueueForContext;
@property (strong, nonatomic) dispatch_queue_t serialQueueForFileCoordinator;
@property (strong, nonatomic) MEGACoreDataStack *stack;

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
        _serialQueueForContext = dispatch_queue_create("nz.mega.cameraUpload.recordManager.context", DISPATCH_QUEUE_SERIAL);
        _serialQueueForFileCoordinator = dispatch_queue_create("nz.mega.cameraUpload.recordManager.coordinator", DISPATCH_QUEUE_SERIAL);
        
        _stack = [[MEGACoreDataStack alloc] initWithModelName:@"CameraUpload" storeURL:[NSURL.mnz_cameraUploadURL URLByAppendingPathComponent:@"CameraUpload.sqlite"]];
    }
    
    return self;
}

- (LocalFileNameGenerator *)fileNameCoordinator {
    dispatch_sync(self.serialQueueForFileCoordinator, ^{
        if (self->_fileNameCoordinator == nil) {
            self->_fileNameCoordinator = [[LocalFileNameGenerator alloc] initWithBackgroundContext:self.backgroundContext];
        }
    });
    
    return _fileNameCoordinator;
}

/// We need to re-create background context after login from a logout
- (NSManagedObjectContext *)backgroundContext {
    dispatch_sync(self.serialQueueForContext, ^{
        if (self->_backgroundContext == nil) {
            self->_backgroundContext = [self.stack newBackgroundContext];
            self->_backgroundContext.undoManager = nil;
        }
    });
    
    return _backgroundContext;
}

- (void)resetDataContext {
    [_backgroundContext performBlockAndWait:^{
        [self->_backgroundContext reset];
    }];
    _backgroundContext = nil;
    _fileNameCoordinator = nil;
    
    [self.stack deleteStore];
}

#pragma mark - access properties of record

- (NSString *)savedIdentifierInRecord:(MOAssetUploadRecord *)record {
    __block NSString *identifier;
    [self.backgroundContext performBlockAndWait:^{
        identifier = record.localIdentifier;
    }];
    
    return identifier;
}

#pragma mark - memory management

- (void)refaultObject:(NSManagedObject *)object {
    [self.backgroundContext performBlock:^{
        [self.backgroundContext refreshObject:object mergeChanges:NO];
    }];
}

#pragma mark - fetch records

- (NSArray<MOAssetUploadRecord *> *)fetchUploadRecordsByIdentifier:(NSString *)identifier shouldPrefetchErrorRecords:(BOOL)prefetchErrorRecords error:(NSError *__autoreleasing  _Nullable *)error {
    NSFetchRequest *request = MOAssetUploadRecord.fetchRequest;
    request.returnsObjectsAsFaults = NO;
    request.predicate = [NSPredicate predicateWithFormat:@"localIdentifier == %@", identifier];
    if (prefetchErrorRecords) {
        [request setRelationshipKeyPathsForPrefetching:@[@"errorPerLaunch", @"errorPerLogin"]];
    }
    
    return [self fetchUploadRecordsByFetchRequest:request error:error];
}

- (NSArray<MOAssetUploadRecord *> *)queueUpUploadRecordsByStatuses:(NSArray<NSNumber *> *)statuses fetchLimit:(NSUInteger)fetchLimit mediaType:(PHAssetMediaType)mediaType error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    __block NSArray<MOAssetUploadRecord *> *records = @[];
    __block NSError *coreDataError = nil;
    [self.backgroundContext performBlockAndWait:^{
        NSFetchRequest *request = MOAssetUploadRecord.fetchRequest;
        request.returnsObjectsAsFaults = NO;
        request.fetchLimit = fetchLimit;
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(status IN %@) AND (mediaType == %@)", statuses, @(mediaType)];
        request.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, [self predicateByFilterAssetUploadRecordError]]];
        [request setRelationshipKeyPathsForPrefetching:@[@"errorPerLaunch", @"errorPerLogin", @"fileNameRecord"]];
        records = [self.backgroundContext executeFetchRequest:request error:&coreDataError];
        
        for (MOAssetUploadRecord *record in records) {
            record.status = @(CameraAssetUploadStatusQueuedUp);
        }
    }];
    
    if (error != NULL) {
        *error = coreDataError;
    }
    
    return records;
}

#if DEBUG

- (NSArray<MOAssetUploadRecord *> *)fetchAllUploadRecords:(NSError * _Nullable __autoreleasing * _Nullable)error {
    return [self fetchUploadRecordsByFetchRequest:MOAssetUploadRecord.fetchRequest error:error];
}

#endif

- (NSArray<MOAssetUploadRecord *> *)fetchUploadRecordsByStatuses:(NSArray<NSNumber *> *)statuses error:(NSError * _Nullable __autoreleasing *)error {
    NSFetchRequest *request = MOAssetUploadRecord.fetchRequest;
    request.returnsObjectsAsFaults = NO;
    request.predicate = [NSPredicate predicateWithFormat:@"status IN %@", statuses];
    return [self fetchUploadRecordsByFetchRequest:request error:error];
}

- (NSArray<MOAssetUploadRecord *> *)fetchUploadRecordsByMediaTypes:(NSArray<NSNumber *> *)mediaTypes statuses:(NSArray<NSNumber *> *)statuses error:(NSError * _Nullable __autoreleasing *)error {
    NSFetchRequest *request = MOAssetUploadRecord.fetchRequest;
    request.returnsObjectsAsFaults = NO;
    request.predicate = [NSPredicate predicateWithFormat:@"(mediaType IN %@) AND (status IN %@)", mediaTypes, statuses];
    return [self fetchUploadRecordsByFetchRequest:request error:error];
}

- (NSArray<MOAssetUploadRecord *> *)fetchUploadRecordsByFetchRequest:(NSFetchRequest *)request error:(NSError * _Nullable __autoreleasing *)error {
    __block NSArray<MOAssetUploadRecord *> *records = @[];
    __block NSError *coreDataError = nil;
    [self.backgroundContext performBlockAndWait:^{
        records = [self.backgroundContext executeFetchRequest:request error:&coreDataError];
    }];
    
    if (error != NULL) {
        *error = coreDataError;
    }
    
    return records;
}

#pragma mark - fetch records by media types

- (NSArray<MOAssetUploadRecord *> *)fetchUploadRecordsByMediaTypes:(NSArray<NSNumber *> *)mediaTypes includeAdditionalMediaSubtypes:(BOOL)includeAdditionalMediaSubtypes error:(NSError * _Nullable __autoreleasing *)error {
    NSFetchRequest *request = MOAssetUploadRecord.fetchRequest;
    request.returnsObjectsAsFaults = NO;
    NSPredicate *mediaTypePredicate = [NSPredicate predicateWithFormat:@"mediaType IN %@", mediaTypes];
    
    if (includeAdditionalMediaSubtypes) {
        request.predicate = mediaTypePredicate;
    } else {
        NSPredicate *additionalSubtypePredicate = [NSPredicate predicateWithFormat:@"additionalMediaSubtypes == %@", NSNull.null];
        request.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[mediaTypePredicate, additionalSubtypePredicate]];
    }
    
    return [self fetchUploadRecordsByFetchRequest:request error:error];
}

#if DEBUG

- (NSArray<MOAssetUploadRecord *> *)fetchUploadRecordsByMediaTypes:(NSArray<NSNumber *> *)mediaTypes mediaSubtypes:(PHAssetMediaSubtype)subtypes includeAdditionalMediaSubtypes:(BOOL)includeAdditionalMediaSubtypes error:(NSError * _Nullable __autoreleasing *)error {
    NSFetchRequest *request = MOAssetUploadRecord.fetchRequest;
    request.returnsObjectsAsFaults = NO;
    NSPredicate *mediaTypePredicate = [NSPredicate predicateWithFormat:@"mediaType IN %@", mediaTypes];
    NSPredicate *mediaSubtypesPredicate = [NSPredicate predicateWithFormat:@"(mediaSubtypes != %@) AND ((mediaSubtypes & %lu) == %lu)", NSNull.null, subtypes, subtypes];
    
    if (includeAdditionalMediaSubtypes) {
        request.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[mediaTypePredicate, mediaSubtypesPredicate]];
    } else {
        NSPredicate *additionalSubtypePredicate = [NSPredicate predicateWithFormat:@"additionalMediaSubtypes == %@", NSNull.null];
        request.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[mediaTypePredicate, mediaSubtypesPredicate, additionalSubtypePredicate]];
    }
    
    return [self fetchUploadRecordsByFetchRequest:request error:error];
}

#endif

- (NSArray<MOAssetUploadRecord *> *)fetchUploadRecordsByMediaTypes:(NSArray<NSNumber *> *)mediaTypes additionalMediaSubtypes:(PHAssetMediaSubtype)mediaSubtypes error:(NSError *__autoreleasing  _Nullable *)error {
    NSFetchRequest *request = MOAssetUploadRecord.fetchRequest;
    request.returnsObjectsAsFaults = NO;
    NSPredicate *mediaTypePredicate = [NSPredicate predicateWithFormat:@"mediaType IN %@", mediaTypes];
    NSPredicate *mediaSubtypePredicate = [NSPredicate predicateWithFormat:@"(additionalMediaSubtypes != %@) AND ((additionalMediaSubtypes & %lu) == %lu)", NSNull.null, mediaSubtypes, mediaSubtypes];
    request.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[mediaTypePredicate, mediaSubtypePredicate]];
    
    return [self fetchUploadRecordsByFetchRequest:request error:error];
}

#pragma mark - fetch upload counts

- (NSUInteger)finishedRecordsCountByMediaTypes:(NSArray<NSNumber *> *)mediaTypes error:(NSError * _Nullable __autoreleasing *)error {
    NSFetchRequest *request = MOAssetUploadRecord.fetchRequest;
    request.predicate = [NSPredicate predicateWithFormat:@"(status == %@) AND (mediaType IN %@)", @(CameraAssetUploadStatusDone), mediaTypes];
    return [self countForFetchRequest:request error:error];
}

- (NSUInteger)totalRecordsCountByMediaTypes:(NSArray<NSNumber *> *)mediaTypes includeUploadErrorRecords:(BOOL)includeUploadErrorRecords error:(NSError * _Nullable __autoreleasing *)error {
    NSFetchRequest *request = MOAssetUploadRecord.fetchRequest;
    NSPredicate *mediaTypePredicate = [NSPredicate predicateWithFormat:@"mediaType IN %@", mediaTypes];
    if (includeUploadErrorRecords) {
        request.predicate = mediaTypePredicate;
    } else {
        request.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[mediaTypePredicate, [self predicateByFilterAssetUploadRecordError]]];
    }
    
    return [self countForFetchRequest:request error:error];
}

- (NSUInteger)pendingRecordsCountByMediaTypes:(NSArray<NSNumber *> *)mediaTypes error:(NSError * _Nullable __autoreleasing *)error {
    NSFetchRequest *request = MOAssetUploadRecord.fetchRequest;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(status <> %@) AND (mediaType IN %@)", @(CameraAssetUploadStatusDone), mediaTypes];
    request.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, [self predicateByFilterAssetUploadRecordError]]];
    return [self countForFetchRequest:request error:error];
}

- (NSUInteger)uploadingRecordsCountWithError:(NSError * _Nullable __autoreleasing *)error {
    NSFetchRequest *request = MOAssetUploadRecord.fetchRequest;
    request.predicate = [NSPredicate predicateWithFormat:@"status == %@", @(CameraAssetUploadStatusUploading)];
    return [self countForFetchRequest:request error:error];
}

- (NSUInteger)pendingForUploadingRecordsCountByMediaTypes:(NSArray<NSNumber *> *)mediaTypes error:(NSError * _Nullable __autoreleasing *)error {
    NSFetchRequest *request = MOAssetUploadRecord.fetchRequest;
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"(NOT (status IN %@)) AND (mediaType IN %@)", @[@(CameraAssetUploadStatusDone), @(CameraAssetUploadStatusUploading)], mediaTypes];
    request.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicate, [self predicateByFilterAssetUploadRecordError]]];
    return [self countForFetchRequest:request error:error];
}

- (NSUInteger)countForFetchRequest:(NSFetchRequest *)request error:(NSError * _Nullable __autoreleasing *)error {
    __block NSUInteger count = 0;
    __block NSError *coreDataError = nil;
    [self.backgroundContext performBlockAndWait:^{
        count = [self.backgroundContext countForFetchRequest:request error:&coreDataError];
    }];
    
    if (error != NULL) {
        *error = coreDataError;
    }
    
    return count;
}

#pragma mark - save records

- (BOOL)saveChangesIfNeededWithError:(NSError *__autoreleasing  _Nullable *)error {
    __block NSError *coreDataError = nil;
    [self.backgroundContext performBlockAndWait:^{
        if (self.backgroundContext.hasChanges) {
            [self.backgroundContext save:&coreDataError];
        }
    }];
    
    if (error != NULL) {
        *error = coreDataError;
    }
    
    return coreDataError == nil;
}

#pragma mark - update records

- (BOOL)updateUploadRecord:(MOAssetUploadRecord *)record withStatus:(CameraAssetUploadStatus)status error:(NSError *__autoreleasing  _Nullable *)error {
    __block NSError *coreDataError = nil;
    @try {
        [self.backgroundContext performBlockAndWait:^{
            record.status = @(status);
            if (status == CameraAssetUploadStatusFailed) {
                if (record.errorPerLaunch == nil) {
                    record.errorPerLaunch = [self createErrorRecordPerLaunchForLocalIdentifier:record.localIdentifier];
                }
                record.errorPerLaunch.errorCount = @(record.errorPerLaunch.errorCount.unsignedIntegerValue + 1);
                
                if (record.errorPerLogin == nil) {
                    record.errorPerLogin = [self createErrorRecordPerLoginForLocalIdentifier:record.localIdentifier];
                }
                record.errorPerLogin.errorCount = @(record.errorPerLogin.errorCount.unsignedIntegerValue + 1);
                
                MEGALogInfo(@"[Camera Upload] %@ upload failed with error per launch count: %@, error per login count: %@", record, record.errorPerLaunch.errorCount, record.errorPerLogin.errorCount);
            } else if (status == CameraAssetUploadStatusDone) {
                MOAssetUploadErrorPerLaunch *errorPerLaunch = [record errorPerLaunch];
                if (errorPerLaunch) {
                    [self.backgroundContext deleteObject:errorPerLaunch];
                }
                
                MOAssetUploadErrorPerLogin *errorPerLogin = [record errorPerLogin];
                if (errorPerLogin) {
                    [self.backgroundContext deleteObject:errorPerLogin];
                }
            }
            
            [self.backgroundContext save:&coreDataError];
            
            if (record.errorPerLaunch.errorCount.unsignedIntegerValue > MaximumUploadRetryPerLaunchCount || record.errorPerLogin.errorCount.unsignedIntegerValue > MaximumUploadRetryPerLaunchCount) {
                [NSNotificationCenter.defaultCenter postNotificationName:MEGACameraUploadStatsChangedNotification object:nil];
            }
        }];
        
    } @catch (NSException *exception) {
        if ([CoreDataErrorHandler hasSQLiteFullErrorInException:exception]) {
            [NSNotificationCenter.defaultCenter postNotificationName:MEGASQLiteDiskFullNotification object:nil];
        } else {
            coreDataError = [NSError mnz_cameraUploadCoreDataException:exception];
        }
    } @finally {
        if (error != NULL) {
            *error = coreDataError;
        }
        
        return coreDataError == nil;
    }
}

#pragma mark - delete records

#if DEBUG

- (BOOL)deleteAllUploadRecordsWithError:(NSError * _Nullable __autoreleasing * _Nullable)error {
    __block NSError *coreDataError = nil;
    [self.backgroundContext performBlockAndWait:^{
        NSFetchRequest *request = MOAssetUploadRecord.fetchRequest;
        NSBatchDeleteRequest *deleteRequest = [[NSBatchDeleteRequest alloc] initWithFetchRequest:request];
        [self.backgroundContext executeRequest:deleteRequest error:&coreDataError];
    }];
    
    if (error != NULL) {
        *error = coreDataError;
    }
    
    return coreDataError == nil;
}

#endif

- (BOOL)deleteUploadRecord:(MOAssetUploadRecord *)record error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    __block NSError *coreDataError = nil;
    [self.backgroundContext performBlockAndWait:^{
        [self.backgroundContext deleteObject:record];
        [self.backgroundContext save:&coreDataError];
    }];
    
    if (error != NULL) {
        *error = coreDataError;
    }
    
    return coreDataError == nil;
}

#pragma mark - error record management

- (BOOL)deleteAllErrorRecordsPerLaunchWithError:(NSError * _Nullable __autoreleasing * _Nullable)error {
    __block NSError *coreDataError = nil;
    [self.backgroundContext performBlockAndWait:^{
        NSFetchRequest *request = MOAssetUploadErrorPerLaunch.fetchRequest;
        NSBatchDeleteRequest *deleteRequest = [[NSBatchDeleteRequest alloc] initWithFetchRequest:request];
        [self.backgroundContext executeRequest:deleteRequest error:&coreDataError];
    }];
    
    if (error != NULL) {
        *error = coreDataError;
    }
    
    return coreDataError == nil;
}

#pragma mark - helper methods

- (MOAssetUploadErrorPerLaunch *)createErrorRecordPerLaunchForLocalIdentifier:(NSString *)identifier {
    if (self.backgroundContext == nil) return nil;
    
    MOAssetUploadErrorPerLaunch *errorPerLaunch = [NSEntityDescription insertNewObjectForEntityForName:@"AssetUploadErrorPerLaunch" inManagedObjectContext:self.backgroundContext];
    errorPerLaunch.localIdentifier = identifier;
    errorPerLaunch.errorCount = @(0);
    return errorPerLaunch;
}

- (MOAssetUploadErrorPerLogin *)createErrorRecordPerLoginForLocalIdentifier:(NSString *)identifier {
    if (self.backgroundContext == nil) return nil;
    
    MOAssetUploadErrorPerLogin *errorPerLogin = [NSEntityDescription insertNewObjectForEntityForName:@"AssetUploadErrorPerLogin" inManagedObjectContext:self.backgroundContext];
    errorPerLogin.localIdentifier = identifier;
    errorPerLogin.errorCount = @(0);
    return errorPerLogin;
}

- (NSPredicate *)predicateByFilterAssetUploadRecordError {
    NSPredicate *errorPerLaunch = [NSPredicate predicateWithFormat:@"(errorPerLaunch == %@) OR (errorPerLaunch.errorCount <= %@)", NSNull.null, @(MaximumUploadRetryPerLaunchCount)];
    NSPredicate *errorPerLogin = [NSPredicate predicateWithFormat:@"(errorPerLogin == %@) OR (errorPerLogin.errorCount <= %@)", NSNull.null, @(MaximumUploadRetryPerLoginCount)];
    return [NSCompoundPredicate andPredicateWithSubpredicates:@[errorPerLaunch, errorPerLogin]];
}

@end
