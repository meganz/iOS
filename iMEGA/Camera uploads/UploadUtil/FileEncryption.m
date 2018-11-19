
#import "FileEncryption.h"
#import "MEGASdkManager.h"

static const NSUInteger EncryptionProposedChunkSizeInBytes = 100 * 1024 * 1024;
static const NSUInteger EncryptionMinimumChunkSizeInBytes = 5 * 1024 * 1024;

static NSString * const EncryptionErrorDomain = @"nz.mega.cameraUpload.encryption";
static NSString * const EncryptionErrorMessageKey = @"message";

@interface FileEncryption ()

@property (strong, nonatomic) NSURL *outputDirectoryURL;
@property (nonatomic) unsigned long long fileSize;
@property (nonatomic) NSUInteger chunkSize;
@property (strong, nonatomic) MEGABackgroundMediaUpload *mediaUpload;

@end

@implementation FileEncryption

- (instancetype)initWithMediaUpload:(MEGABackgroundMediaUpload *)mediaUpload outputDirectoryURL:(NSURL *)outputDirectoryURL {
    self = [super init];
    if (self) {
        _outputDirectoryURL = outputDirectoryURL;
        _mediaUpload = mediaUpload;
    }

    return self;
}

- (void)encryptFileAtURL:(NSURL *)fileURL completion:(void (^)(BOOL success, unsigned long long fileSize, NSDictionary<NSString *, NSURL *> *chunkURLsKeyedByUploadSuffix, NSError *error))completion {
    NSError *error;
    [NSFileManager.defaultManager createDirectoryAtPath:self.outputDirectoryURL.path withIntermediateDirectories:YES attributes:nil error:&error];
    NSDictionary<NSFileAttributeKey, id> *attributeDict = [NSFileManager.defaultManager attributesOfItemAtPath:fileURL.path error:&error];
    
    self.fileSize = attributeDict.fileSize;
    unsigned long long deviceFreeSize = [attributeDict[NSFileSystemFreeSize] unsignedLongLongValue];
    
    if (error || ![NSFileManager.defaultManager isWritableFileAtPath:fileURL.path] || deviceFreeSize < EncryptionMinimumChunkSizeInBytes) {
        completion(NO, 0, nil, error);
        return;
    }
    
    self.chunkSize = [self calculateChunkSizeByDeviceFreeSize:deviceFreeSize];
    
    NSDictionary *chunkURLsKeyedByUploadSuffix = [self encryptedChunkURLsKeyedByUploadSuffixForFileAtURL:fileURL error:&error];
    if (error || chunkURLsKeyedByUploadSuffix.allValues.count == 0) {
        completion(NO, 0, nil, error);
    } else {
        completion(YES, self.fileSize, chunkURLsKeyedByUploadSuffix, nil);
    }
}

- (NSDictionary<NSString *, NSURL *> *)encryptedChunkURLsKeyedByUploadSuffixForFileAtURL:(NSURL *)fileURL error:(NSError **)error {
    NSError *positionError;
    NSArray<NSNumber *> *chunkPositions = [self calculteChunkPositionsForFileAtURL:fileURL error:&positionError];
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
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:fileURL.path];
    
    NSUInteger chunkIndex = 0;
    for (NSNumber *position in reversedPositions) {
        NSString *chunkName = [NSString stringWithFormat:@"chunk%lu", chunkIndex];
        NSURL *chunkURL = [self.outputDirectoryURL URLByAppendingPathComponent:chunkName];
        NSString *suffix;
        unsigned length = (unsigned)(lastPosition - position.unsignedLongLongValue);
        if ([self.mediaUpload encryptFileAtPath:fileURL.path startPosition:position.unsignedLongLongValue length:&length outputFilePath:chunkURL.path urlSuffix:&suffix adjustsSizeOnly:NO]) {
            chunksDict[suffix] = chunkURL;
            [fileHandle truncateFileAtOffset:position.unsignedLongLongValue];
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

- (NSArray<NSNumber *> *)calculteChunkPositionsForFileAtURL:(NSURL *)fileURL error:(NSError **)error {
    NSMutableArray<NSNumber *> *chunkPositions = [NSMutableArray arrayWithObject:@(0)];
    
    unsigned chunkSize = (unsigned)self.chunkSize;
    unsigned long long startPosition = 0;
//    NSUInteger chunkIndex = 0;
//    NSURL *chunkURL = [self.outputDirectoryURL URLByAppendingPathComponent:[NSString stringWithFormat:@"chunk%lu", chunkIndex]];
//    NSString *suffix;
    
    while (startPosition < self.fileSize) {
        if ([self.mediaUpload encryptFileAtPath:fileURL.path startPosition:startPosition length:&chunkSize outputFilePath:nil urlSuffix:nil adjustsSizeOnly:YES]) {
            startPosition = startPosition + chunkSize;
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

//- (BOOL)encryptFileAtURL:(NSURL *)fileURL uploadSuffix:(NSString **)uploadSuffix {
//    NSFileHandle *fileHandle;
//    if (self.shouldTruncateChunks) {
//        NSError *error;
//        fileHandle = [NSFileHandle fileHandleForWritingToURL:fileURL error:&error];
//        if (error) {
//            fileHandle = nil;
//        }
//    }
    
//    unsigned long long startPosition = 0;
//    NSUInteger chunkIndex = 0;
//    while (startPosition < self.fileSize) {
//        NSString *chunkOutputPath = [self.outputFileURL URLByAppendingPathExtension:[NSString stringWithFormat:@"chunk%lu", chunkIndex]].path;
//        NSUInteger length = self.chunkSize;
//        if([self.mediaUpload encryptFileAtPath:fileURL.path startPosition:startPosition length:&length outputFilePath:chunkOutputPath urlSuffix:uploadSuffix]) {
//            startPosition = startPosition + length;
//
//            // ???
//        } else {
//            return NO;
//        }
//    }
//
//    return YES;
//}

- (NSUInteger)calculateChunkSizeByDeviceFreeSize:(unsigned long long)deviceFreeSize {
    unsigned long long chunkSize = MIN(deviceFreeSize, EncryptionProposedChunkSizeInBytes);
    return MIN(chunkSize, self.fileSize);
}

@end
