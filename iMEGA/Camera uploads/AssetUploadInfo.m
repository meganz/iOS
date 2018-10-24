
#import "AssetUploadInfo.h"
#import "MEGASdkManager.h"

@implementation AssetUploadInfo

- (NSURL *)fileURL {
    return [self.directoryURL URLByAppendingPathComponent:self.fileName];
}

- (NSURL *)encryptedURL {
    return [self.fileURL URLByAppendingPathExtension:@"encrypted"];
}

- (NSURL *)uploadURL {
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", self.uploadURLString, self.uploadURLStringSuffix]];
}

- (NSURL *)previewURL {
    return [self.fileURL URLByAppendingPathExtension:@"preview"];
}

- (NSURL *)thumbnailURL {
    return [self.fileURL URLByAppendingPathExtension:@"thumbnail"];
}

#pragma mark - NSCoding protocol

- (void)encodeWithCoder:(nonnull NSCoder *)aCoder {
    [aCoder encodeObject:self.fileName forKey:@"fileName"];
    [aCoder encodeInteger:self.fileSize forKey:@"fileSize"];
    [aCoder encodeObject:self.fingerprint forKey:@"fingerprint"];
    [aCoder encodeObject:self.originalFingerprint forKey:@"originalFingerprint"];
    [aCoder encodeObject:self.directoryURL forKey:@"directoryURL"];
    [aCoder encodeObject:self.mediaUpload.serialize forKey:@"mediaUpload"];
    [aCoder encodeObject:@(self.parentHandle) forKey:@"parentHandle"];
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        _fileName = [aDecoder decodeObjectForKey:@"fileName"];
        _fileSize = [aDecoder decodeIntegerForKey:@"fileSize"];
        _fingerprint = [aDecoder decodeObjectForKey:@"fingerprint"];
        _originalFingerprint = [aDecoder decodeObjectForKey:@"originalFingerprint"];
        _directoryURL = [aDecoder decodeObjectForKey:@"directoryURL"];
        _parentHandle = [[aDecoder decodeObjectForKey:@"parentHandle"] unsignedLongLongValue];
        NSData *serializedData = [aDecoder decodeObjectForKey:@"mediaUpload"];
        _mediaUpload = [[MEGASdkManager sharedMEGASdk] resumeBackgroundMediaUploadBySerializedData:serializedData];
    }
    
    return self;
}

@end
