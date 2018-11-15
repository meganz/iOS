
#import "FileEncryption.h"
#import "MEGASdkManager.h"

static const NSUInteger MaximumEncryptionChunkSizeInBytes = 2^32 -1;

@interface FileEncryption ()

@property (strong, nonatomic) NSURL *outputFileURL;
@property (nonatomic) unsigned long long fileSize;
@property (nonatomic) NSUInteger chunkSize;
@property (strong, nonatomic) MEGABackgroundMediaUpload *mediaUpload;

@end

@implementation FileEncryption

- (instancetype)initWithMediaUpload:(MEGABackgroundMediaUpload *)mediaUpload outputFileURL:(NSURL *)outputFileURL {
    self = [super init];
    if (self) {
        _outputFileURL = outputFileURL;
        _mediaUpload = mediaUpload;
    }

    return self;
}

- (void)encryptFileAtURL:(NSURL *)fileURL completion:(void (^)(BOOL success, unsigned long long fileSize, NSString *uploadSuffix))completion {
    NSError *error;
    NSDictionary<NSFileAttributeKey, id> *attributeDict = [NSFileManager.defaultManager attributesOfItemAtPath:fileURL.path error:&error];
    if (error) {
        completion(NO, 0, nil);
        return;
    }
    
    self.fileSize = attributeDict.fileSize;
//    self.shouldTruncateChunks = [NSFileManager.defaultManager isWritableFileAtPath:fileURL.path];
    self.chunkSize = [self calculateChunkSizeByDeviceFreeSize:[attributeDict[NSFileSystemFreeSize] unsignedLongLongValue]];
    
    NSString *uploadSuffix;
    if ([self encryptFileAtURL:fileURL uploadSuffix:&uploadSuffix]) {
        completion(YES, self.fileSize, uploadSuffix);
    } else {
        completion(NO, self.fileSize, uploadSuffix);
    }
}

- (BOOL)encryptFileAtURL:(NSURL *)fileURL uploadSuffix:(NSString **)uploadSuffix {
//    NSFileHandle *fileHandle;
//    if (self.shouldTruncateChunks) {
//        NSError *error;
//        fileHandle = [NSFileHandle fileHandleForWritingToURL:fileURL error:&error];
//        if (error) {
//            fileHandle = nil;
//        }
//    }
    
    unsigned long long startPosition = 0;
    NSUInteger chunkIndex = 0;
    while (startPosition < self.fileSize) {
        NSString *chunkOutputPath = [self.outputFileURL URLByAppendingPathExtension:[NSString stringWithFormat:@"chunk%lu", chunkIndex]].path;
        NSUInteger length = self.chunkSize;
        if([self.mediaUpload encryptFileAtPath:fileURL.path startPosition:startPosition length:&length outputFilePath:chunkOutputPath urlSuffix:uploadSuffix]) {
            startPosition = startPosition + length;
            
            // ???
        } else {
            return NO;
        }
    }
 
    return YES;
}

- (NSUInteger)calculateChunkSizeByDeviceFreeSize:(unsigned long long)deviceFreeSize {
    unsigned long long chunkSize = 0;
    if (deviceFreeSize > self.fileSize * 10) {
        chunkSize = self.fileSize;
    } else if (deviceFreeSize > self.fileSize * 5) {
        chunkSize = self.fileSize / 2;
    } else if (deviceFreeSize > self.fileSize) {
        chunkSize = self.fileSize / 10;
    } else {
        chunkSize = deviceFreeSize / 10;
    }
    
    if (chunkSize > MaximumEncryptionChunkSizeInBytes) {
        chunkSize = MaximumEncryptionChunkSizeInBytes;
    }
    
    return chunkSize;
}

@end
