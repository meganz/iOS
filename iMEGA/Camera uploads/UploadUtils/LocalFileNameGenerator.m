#import "LocalFileNameGenerator.h"
#import "NSString+MNZCategory.h"
#import "MEGAStore.h"
#import "MOAssetUploadFileNameRecord+CoreDataClass.h"
#import "MOAssetUploadRecord+CoreDataClass.h"

@interface LocalFileNameGenerator ()

@property (strong, nonatomic, nullable) NSManagedObjectContext *backgroundContext;

@end

@implementation LocalFileNameGenerator

- (instancetype)initWithBackgroundContext:(NSManagedObjectContext *)context {
    self = [super init];
    if (self) {
        _backgroundContext = context;
    }
    
    return self;
}

- (NSString *)generateUniqueLocalFileNameForUploadRecord:(MOAssetUploadRecord *)record withOriginalFileName:(NSString *)originalFileName {
    __block NSString *localUniqueFileName;
    [self.backgroundContext performBlockAndWait:^{
        if (record.fileNameRecord) {
            localUniqueFileName = record.fileNameRecord.localUniqueFileName;
        } else {
            NSString *fileExtension = originalFileName.pathExtension;
            NSArray<MOAssetUploadFileNameRecord *> *similarFileNameRecords = [self searchSimilarNameRecordsByFileExtension:fileExtension fileNamePrefix:originalFileName.stringByDeletingPathExtension error:nil];
            if (similarFileNameRecords.count > 0) {
                localUniqueFileName = [self calculateUniqueFileNameFromOriginalFileName:originalFileName similarFileNameRecords:similarFileNameRecords];
            } else {
                localUniqueFileName = originalFileName;
            }
            
            MEGALogDebug(@"[Camera Upload] %@ local name generated for %@", localUniqueFileName, record.localIdentifier);
            
            [self saveLocalUniqueFileName:localUniqueFileName fileExtension:fileExtension forUploadRecord:record error:nil];
        }
    }];
    
    return localUniqueFileName;
}

#pragma mark - the algorithm to generate local unique file name

- (NSString *)calculateUniqueFileNameFromOriginalFileName:(NSString *)originalFileName similarFileNameRecords:(NSArray<MOAssetUploadFileNameRecord *> *)fileNameRecords {
    if (fileNameRecords.count == 0) {
        return originalFileName;
    }
    
    NSString *uniqueFileName = originalFileName;
    
    NSComparator fileNameComparator = ^(NSString *s1, NSString *s2) {
        return [s1 compare:s2];
    };
    
    NSMutableArray<NSString *> *sortedFileNames = [NSMutableArray arrayWithCapacity:fileNameRecords.count];
    for (MOAssetUploadFileNameRecord *record in fileNameRecords) {
        [sortedFileNames addObject:record.localUniqueFileName];
    }
    
    [sortedFileNames sortUsingComparator:fileNameComparator];
    
    NSUInteger fileNameSuffixStep = 0;
    NSInteger matchingIndex = 0;
    while (matchingIndex != NSNotFound) {
        matchingIndex = [sortedFileNames indexOfObject:uniqueFileName inSortedRange:NSMakeRange(0, sortedFileNames.count) options:NSBinarySearchingLastEqual usingComparator:fileNameComparator];
        if (matchingIndex != NSNotFound) {
            fileNameSuffixStep++;
            uniqueFileName = [[NSString stringWithFormat:@"%@_%ld", originalFileName.stringByDeletingPathExtension, (long)fileNameSuffixStep] stringByAppendingPathExtension:originalFileName.pathExtension];
        }
    }
    
    return uniqueFileName;
}

#pragma mark - search local file name records

#if DEBUG

- (NSArray<MOAssetUploadFileNameRecord *> *)fetchAllNameRecordsWithError:(NSError * _Nullable __autoreleasing * _Nullable)error {
    __block NSArray<MOAssetUploadFileNameRecord *> *fileNameRecords = [NSArray array];
    __block NSError *coreDataError = nil;
    [self.backgroundContext performBlockAndWait:^{
        NSFetchRequest *request = MOAssetUploadFileNameRecord.fetchRequest;
        request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"localUniqueFileName" ascending:NO]];
        fileNameRecords = [self.backgroundContext executeFetchRequest:request error:&coreDataError];
    }];
    
    if (error != NULL) {
        *error = coreDataError;
    }
    
    return fileNameRecords;
}

#endif

- (NSArray<MOAssetUploadFileNameRecord *> *)searchSimilarNameRecordsByFileExtension:(NSString *)extension fileNamePrefix:(NSString *)prefix error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    __block NSArray<MOAssetUploadFileNameRecord *> *fileNameRecords = [NSArray array];
    if (prefix == nil) {
        return fileNameRecords;
    }
    
    __block NSError *coreDataError = nil;
    [self.backgroundContext performBlockAndWait:^{
        NSFetchRequest *request = MOAssetUploadFileNameRecord.fetchRequest;
        request.predicate = [NSPredicate predicateWithFormat:@"(fileExtension == %@) AND (localUniqueFileName BEGINSWITH[cd] %@)", extension, prefix];
        fileNameRecords = [self.backgroundContext executeFetchRequest:request error:&coreDataError];
    }];
    
    if (error != NULL) {
        *error = coreDataError;
    }
    
    return fileNameRecords;
}

#pragma mark - save local unique file name to core data

- (BOOL)saveLocalUniqueFileName:(NSString *)name fileExtension:(NSString *)extension forUploadRecord:(MOAssetUploadRecord *)record error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    if (self.backgroundContext == nil) return NO;
    
    __block NSError *coreDataError = nil;
    [self.backgroundContext performBlockAndWait:^{
        if (record.fileNameRecord == nil) {
            record.fileNameRecord = [NSEntityDescription insertNewObjectForEntityForName:@"AssetUploadFileNameRecord" inManagedObjectContext:self.backgroundContext];
        }
        
        record.fileNameRecord.localUniqueFileName = name;
        record.fileNameRecord.fileExtension = extension;
        
        [self.backgroundContext save:&coreDataError];
    }];
    
    if (error != NULL) {
        *error = coreDataError;
    }
    
    return coreDataError == nil;
}

@end
