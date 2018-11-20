
#import "FileEncryption.h"
#import "MEGASdkManager.h"
#import "NSFileManager+MNZCategory.h"

static const NSUInteger EncryptionProposedChunkSizeForTruncating = 100 * 1024 * 1024;
static const NSUInteger EncryptionMinimumChunkSize = 5 * 1024 * 1024;
static const NSUInteger EncryptionProposedChunkSizeWithoutTruncating = 1024 * 1024 * 1024;

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
    unsigned long long deviceFreeSize = [NSFileManager.defaultManager deviceFreeSize];
    
    MEGALogDebug(@"[Camera Upload] input file size %.2f M, device free size %.2f M", self.fileSize / 1024.0 / 1024.0, deviceFreeSize / 1024.0 / 1024.0);
    
    if (error) {
        completion(NO, 0, nil, error);
        return;
    }
    
    if (self.shouldTruncateFile) {
        if (deviceFreeSize < EncryptionMinimumChunkSize) {
            completion(NO, 0, nil, [self noEnoughFreeSpaceError]);
            return;
        }
        
        if (![NSFileManager.defaultManager isWritableFileAtPath:fileURL.path]) {
            completion(NO, 0, nil, [NSError errorWithDomain:EncryptionErrorDomain code:0 userInfo:@{EncryptionErrorMessageKey : [NSString stringWithFormat:@"no write permission for file %@", fileURL]}]);
            return;
        }
    } else {
        if (deviceFreeSize < self.fileSize) {
            completion(NO, 0, nil, [self noEnoughFreeSpaceError]);
            return;
        }
    }

    NSUInteger chunkSize = [self calculateChunkSizeByDeviceFreeSize:deviceFreeSize];
    MEGALogDebug(@"[Camera Upload] encryption chunk size %.2f M", chunkSize / 1024.0 / 1024.0);
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

    MEGALogDebug(@"[Camera Upload] reversed chunk positions %@", chunkPositions);
    
    NSMutableDictionary<NSString *, NSURL *> *chunksDict = [NSMutableDictionary dictionary];
    NSFileHandle *fileHandle;
    if (self.shouldTruncateFile) {
         fileHandle = [NSFileHandle fileHandleForWritingAtPath:fileURL.path];
    }
    
    unsigned long long lastPosition = self.fileSize;
    for (NSInteger chunkIndex = chunkPositions.count - 1; chunkIndex >= 0; chunkIndex --) {
        NSNumber *position = chunkPositions[chunkIndex];
        if (position.unsignedLongLongValue == lastPosition) {
            continue;
        }
        
        unsigned length = (unsigned)(lastPosition - position.unsignedLongLongValue);
        NSString *chunkName = [NSString stringWithFormat:@"chunk%lu", chunkIndex];
        NSURL *chunkURL = [self.outputDirectoryURL URLByAppendingPathComponent:chunkName];
        NSString *suffix;
        if ([self.mediaUpload encryptFileAtPath:fileURL.path startPosition:position.unsignedLongLongValue length:&length outputFilePath:chunkURL.path urlSuffix:&suffix adjustsSizeOnly:NO]) {
            chunksDict[suffix] = chunkURL;
            lastPosition = position.unsignedLongLongValue;
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


/**
 Calculate the chunk size according to the device free space and whether to truncate input file during encryption

 @param deviceFreeSize available space in the device in bytes
 @return proper chunk size to encrypt file, measured in bytes
 */
- (NSUInteger)calculateChunkSizeByDeviceFreeSize:(unsigned long long)deviceFreeSize {
    if (self.shouldTruncateFile) {
        unsigned long long chunkSize = MIN(deviceFreeSize, EncryptionProposedChunkSizeForTruncating);
        return MIN(chunkSize, self.fileSize);
    } else {
        return EncryptionProposedChunkSizeWithoutTruncating;
    }
}


/**
 return a NSError object when there is no encough free space in device

 @return error showing no enough free space
 */
- (NSError *)noEnoughFreeSpaceError {
    return [NSError errorWithDomain:EncryptionErrorDomain code:0 userInfo:@{EncryptionErrorMessageKey : @"no enough device free space for encryption"}];
}

@end
