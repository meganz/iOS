
#import "FileEncryption.h"
#import "MEGASdkManager.h"

static const NSUInteger EncryptionProposedChunkSizeInBytes = 100 * 1024 * 1024;
static const NSUInteger EncryptionMinimumChunkSizeInBytes = 5 * 1024 * 1024;

static NSString * const EncryptionErrorDomain = @"nz.mega.cameraUpload.encryption";
static NSString * const EncryptionErrorMessageKey = @"message";

@interface FileEncryption ()

@property (strong, nonatomic) NSURL *outputDirectoryURL;
@property (nonatomic) unsigned long long fileSize;
@property (strong, nonatomic) MEGABackgroundMediaUpload *mediaUpload;
@property (nonatomic) BOOL shouldTruncateFile;

@end

@implementation FileEncryption

- (instancetype)initWithMediaUpload:(MEGABackgroundMediaUpload *)mediaUpload outputDirectoryURL:(NSURL *)outputDirectoryURL shouldTruncateInputFile:(BOOL)shouldTruncateInputFile {
    self = [super init];
    if (self) {
        _outputDirectoryURL = outputDirectoryURL;
        _mediaUpload = mediaUpload;
        _shouldTruncateFile = shouldTruncateInputFile;
    }

    return self;
}

- (void)encryptFileAtURL:(NSURL *)fileURL completion:(void (^)(BOOL success, unsigned long long fileSize, NSDictionary<NSString *, NSURL *> *chunkURLsKeyedByUploadSuffix, NSError *error))completion {
    NSError *error;
    [NSFileManager.defaultManager createDirectoryAtPath:self.outputDirectoryURL.path withIntermediateDirectories:YES attributes:nil error:&error];
    
    NSDictionary<NSFileAttributeKey, id> *attributeDict = [NSFileManager.defaultManager attributesOfItemAtPath:fileURL.path error:&error];
    
    self.fileSize = attributeDict.fileSize;
    unsigned long long deviceFreeSize = [attributeDict[NSFileSystemFreeSize] unsignedLongLongValue];
    
    if (error) {
        completion(NO, 0, nil, error);
        return;
    }
    
    if (deviceFreeSize < EncryptionMinimumChunkSizeInBytes) {
        completion(NO, 0, nil, [NSError errorWithDomain:EncryptionErrorDomain code:0 userInfo:@{EncryptionErrorMessageKey : @"no enough device free space for encryption"}]);
        return;
    }
    
    if (self.shouldTruncateFile && ![NSFileManager.defaultManager isWritableFileAtPath:fileURL.path]) {
        completion(NO, 0, nil, [NSError errorWithDomain:EncryptionErrorDomain code:0 userInfo:@{EncryptionErrorMessageKey : [NSString stringWithFormat:@"no write permission for file %@", fileURL]}]);
        return;
    }
    
    NSUInteger chunkSize = [self calculateChunkSizeByDeviceFreeSize:deviceFreeSize];
    
    NSDictionary *chunkURLsKeyedByUploadSuffix = [self encryptedChunkURLsKeyedByUploadSuffixForFileAtURL:fileURL chunkSize:chunkSize error:&error];
    if (error || chunkURLsKeyedByUploadSuffix.allValues.count == 0) {
        completion(NO, 0, nil, error);
    } else {
        completion(YES, self.fileSize, chunkURLsKeyedByUploadSuffix, nil);
    }
}

- (NSDictionary<NSString *, NSURL *> *)encryptedChunkURLsKeyedByUploadSuffixForFileAtURL:(NSURL *)fileURL chunkSize:(NSUInteger)chunkSize error:(NSError **)error {
    NSError *positionError;
    NSArray<NSNumber *> *chunkPositions = [self calculteChunkPositionsForFileAtURL:fileURL chunkSize:chunkSize error:&positionError];
    if (positionError) {
        if (error != NULL) {
            *error = positionError;
        }
        
        return @{};
    }
    
    NSMutableArray *reversedPositions = [[[chunkPositions reverseObjectEnumerator] allObjects] mutableCopy];
    unsigned long long lastPosition = [[reversedPositions firstObject] unsignedLongLongValue];
    if (lastPosition != self.fileSize) {
        if (error != NULL) {
            NSString *errorMessage = [NSString stringWithFormat:@"last chunk position doesn't equal to file size %@", fileURL];
            *error = [NSError errorWithDomain:EncryptionErrorDomain code:0 userInfo:@{EncryptionErrorMessageKey : errorMessage}];
        }
        
        return @{};
    }
    
    MEGALogDebug(@"[Camera Upload] start encrypting file %@ at size %llu", fileURL, self.fileSize);
    
    NSMutableDictionary<NSString *, NSURL *> *chunksDict = [NSMutableDictionary dictionary];
    NSFileHandle *fileHandle;
    if (self.shouldTruncateFile) {
         fileHandle = [NSFileHandle fileHandleForWritingAtPath:fileURL.path];
    }
    
    NSUInteger chunkIndex = 0;
    for (NSNumber *position in reversedPositions) {
        NSString *chunkName = [NSString stringWithFormat:@"chunk%lu", chunkIndex];
        NSURL *chunkURL = [self.outputDirectoryURL URLByAppendingPathComponent:chunkName];
        NSString *suffix;
        unsigned length = (unsigned)(lastPosition - position.unsignedLongLongValue);
        if ([self.mediaUpload encryptFileAtPath:fileURL.path startPosition:position.unsignedLongLongValue length:&length outputFilePath:chunkURL.path urlSuffix:&suffix adjustsSizeOnly:NO]) {
            chunksDict[suffix] = chunkURL;
            
            if (self.shouldTruncateFile && fileHandle) {
                [fileHandle truncateFileAtOffset:position.unsignedLongLongValue];
            }
            
            MEGALogDebug(@"[Camera Upload] encrypted %@, file remaining size %llu", chunkName, [NSFileManager.defaultManager attributesOfItemAtPath:fileURL.path error:nil].fileSize);
        } else {
            if (error != NULL) {
                NSString *errorMessage = [NSString stringWithFormat:@"error occurred when to encrypt file %@", fileURL];
                *error = [NSError errorWithDomain:EncryptionErrorDomain code:0 userInfo:@{EncryptionErrorMessageKey : errorMessage}];
            }
            
            return @{};
        }
    }
    
    return chunksDict;
}

- (NSArray<NSNumber *> *)calculteChunkPositionsForFileAtURL:(NSURL *)fileURL chunkSize:(NSUInteger)chunkSize error:(NSError **)error {
    NSMutableArray<NSNumber *> *chunkPositions = [NSMutableArray arrayWithObject:@(0)];
    
    unsigned chunkSizeToBeAdjusted = (unsigned)chunkSize;
    unsigned long long startPosition = 0;
//    NSUInteger chunkIndex = 0;
//    NSURL *chunkURL = [self.outputDirectoryURL URLByAppendingPathComponent:[NSString stringWithFormat:@"chunk%lu", chunkIndex]];
//    NSString *suffix;
    
    while (startPosition < self.fileSize) {
        if ([self.mediaUpload encryptFileAtPath:fileURL.path startPosition:startPosition length:&chunkSizeToBeAdjusted outputFilePath:nil urlSuffix:nil adjustsSizeOnly:YES]) {
            startPosition = startPosition + chunkSizeToBeAdjusted;
            [chunkPositions addObject:@(startPosition)];
        } else {
            if (error != NULL) {
                NSString *errorMessage = [NSString stringWithFormat:@"error occurred when to calculate chunk position for file %@", fileURL];
                *error = [NSError errorWithDomain:EncryptionErrorDomain code:0 userInfo:@{EncryptionErrorMessageKey : errorMessage}];
            }
            
            return @[];
        }
    }
    
    return [chunkPositions copy];
}

- (NSUInteger)calculateChunkSizeByDeviceFreeSize:(unsigned long long)deviceFreeSize {
    unsigned long long chunkSize = MIN(deviceFreeSize, EncryptionProposedChunkSizeInBytes);
    return MIN(chunkSize, self.fileSize);
}

@end
