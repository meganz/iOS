
#import "CameraUploadFileNameRecordManager.h"
#import "NSString+MNZCategory.h"
#import "MEGAStore.h"
#import "MOAssetUploadFileNameRecord+CoreDataClass.h"

@interface CameraUploadFileNameRecordManager ()

@property (strong, nonatomic, nullable) NSManagedObjectContext *backgroundContext;
@property (strong, nonatomic) dispatch_queue_t serialQueue;

@end

@implementation CameraUploadFileNameRecordManager

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
        _serialQueue = dispatch_queue_create("nz.mega.cameraUpload.fileNameManagerSerialQueue", DISPATCH_QUEUE_SERIAL);
    }
    
    return self;
}

- (NSManagedObjectContext *)backgroundContext {
    if (_backgroundContext == nil) {
        _backgroundContext = [MEGAStore.shareInstance newBackgroundContext];
    }
    
    return _backgroundContext;
}

- (void)resetDataContext {
    [_backgroundContext reset];
    _backgroundContext = nil;
}

- (NSString *)localUniqueFileNameForAssetLocalIdentifier:(NSString *)identifier proposedFileName:(NSString *)proposedFileName {
    __block NSString *localUniqueFileName = nil;
    dispatch_sync(self.serialQueue, ^{
        localUniqueFileName = [self fetchLocalFileNameRecordByAssetLocalIdentifier:identifier error:nil].localUniqueFileName;
        if (localUniqueFileName == nil) {
            NSArray<MOAssetUploadFileNameRecord *> *alikeFileNameRecords = [self searchLocalFileNamesByProposedFileName:proposedFileName error:nil];
            if (alikeFileNameRecords.count > 0) {
                localUniqueFileName = [self generateUniqueFileNameFromProposedFileName:proposedFileName alikeFileNameRecords:alikeFileNameRecords];
                
                [self saveLocalUniqueFileName:localUniqueFileName forAssetLocalIdentifier:identifier error:nil];
            }
        }
    });
    
    return localUniqueFileName ?: proposedFileName;
}

#pragma mark - the algorithm to generate local unique file name

- (NSString *)generateUniqueFileNameFromProposedFileName:(NSString *)proposedFileName alikeFileNameRecords:(NSArray<MOAssetUploadFileNameRecord *> *)fileNameRecords {
    if (fileNameRecords.count == 0) {
        return proposedFileName;
    }
    
    NSString *uniqueFileName = proposedFileName;
    
    NSComparator fileNameComparator = ^(NSString *s1, NSString *s2) {
        return [s1 compare:s2];
    };
    
    NSMutableArray<NSString *> *sortedFileNames = [NSMutableArray arrayWithCapacity:fileNameRecords.count];
    for (MOAssetUploadFileNameRecord *record in fileNameRecords) {
        [sortedFileNames addObject:record.localUniqueFileName];
    }
    
    [sortedFileNames sortUsingComparator:fileNameComparator];
    
    NSInteger index = 0;
    while (index != NSNotFound) {
        if (index > 0) {
            uniqueFileName = [[NSString stringWithFormat:@"%@_%ld", proposedFileName.stringByDeletingPathExtension, (long)index] stringByAppendingPathExtension:proposedFileName.pathExtension];
        }
        
        index = [sortedFileNames indexOfObject:uniqueFileName inSortedRange:NSMakeRange(0, sortedFileNames.count) options:NSBinarySearchingFirstEqual usingComparator:fileNameComparator];
    }
    
    return uniqueFileName;
}

#pragma mark - fetch local file name records

- (MOAssetUploadFileNameRecord *)fetchLocalFileNameRecordByAssetLocalIdentifier:(NSString *)identifier error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    __block MOAssetUploadFileNameRecord *fileNameRecord = nil;
    __block NSError *coreDataError = nil;
    [self.backgroundContext performBlockAndWait:^{
        NSFetchRequest *request = MOAssetUploadFileNameRecord.fetchRequest;
        request.predicate = [NSPredicate predicateWithFormat:@"localIdentifier == %@", identifier];
        fileNameRecord = [[self.backgroundContext executeFetchRequest:request error:&coreDataError] firstObject];
    }];
    
    if (error != NULL) {
        *error = coreDataError;
    }
    
    return fileNameRecord;
}

- (NSArray<MOAssetUploadFileNameRecord *> *)searchLocalFileNamesByProposedFileName:(NSString *)proposedFileName error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    __block NSArray<MOAssetUploadFileNameRecord *> *fileNameRecords = [NSArray array];
    __block NSError *coreDataError = nil;
    [self.backgroundContext performBlockAndWait:^{
        NSFetchRequest *request = MOAssetUploadFileNameRecord.fetchRequest;
        request.predicate = [NSPredicate predicateWithFormat:@"localUniqueFileName BEGINSWITH[cd] %@", proposedFileName];
        fileNameRecords = [self.backgroundContext executeFetchRequest:request error:&coreDataError];
    }];
    
    if (error != NULL) {
        *error = coreDataError;
    }
    
    return fileNameRecords;
}

#pragma mark - save local unique file name to core data

- (BOOL)saveLocalUniqueFileName:(NSString *)localUniqueFileName forAssetLocalIdentifier:(NSString *)identifier error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    __block NSError *coreDataError = nil;
    [self.backgroundContext performBlockAndWait:^{
        MOAssetUploadFileNameRecord *record = [self fetchLocalFileNameRecordByAssetLocalIdentifier:identifier error:&coreDataError];
        if (record == nil) {
            record = [NSEntityDescription insertNewObjectForEntityForName:@"AssetUploadFileNameRecord" inManagedObjectContext:self.backgroundContext];
            record.localUniqueFileName = localUniqueFileName;
            record.localIdentifier = identifier;
        } else {
            record.localUniqueFileName = localUniqueFileName;
        }
        
        [self.backgroundContext save:&coreDataError];
    }];
    
    if (error != NULL) {
        *error = coreDataError;
    }
    
    return coreDataError == nil;
}

@end
