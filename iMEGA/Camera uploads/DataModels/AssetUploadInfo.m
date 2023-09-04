#import "AssetUploadInfo.h"

@implementation AssetUploadInfo

#pragma mark - init

- (instancetype)initWithAsset:(PHAsset *)asset savedIdentifier:(NSString *)savedIdentifier parentNode:(MEGANode *)parentNode {
    self = [super init];
    if (self) {
        _asset = asset;
        _savedLocalIdentifier = savedIdentifier;
        _parentNode = parentNode;
    }
    return self;
}

+ (BOOL)supportsSecureCoding {
    return YES;
}

#pragma mark - properties

- (NSURL *)fileURL {
    if (self.fileName == nil) {
        return nil;
    } else {
        return [self.directoryURL URLByAppendingPathComponent:self.fileName];
    }
}

- (NSURL *)previewURL {
    return [self.fileURL URLByAppendingPathExtension:@"preview"];
}

- (NSURL *)thumbnailURL {
    return [self.fileURL URLByAppendingPathExtension:@"thumbnail"];
}

- (NSURL *)encryptionDirectoryURL {
    return [self.directoryURL URLByAppendingPathComponent:@"encryption"];
}

#pragma mark - NSCoding protocol

- (void)encodeWithCoder:(nonnull NSCoder *)aCoder {
    [aCoder encodeObject:self.fileName forKey:@"fileName"];
    [aCoder encodeObject:@(self.fileSize) forKey:@"fileSize"];
    [aCoder encodeObject:self.fingerprint forKey:@"fingerprint"];
    [aCoder encodeObject:self.originalFingerprint forKey:@"originalFingerprint"];
    [aCoder encodeObject:self.directoryURL forKey:@"directoryURL"];
    [aCoder encodeObject:self.mediaUpload.serialize forKey:@"mediaUpload"];
    [aCoder encodeObject:@(self.parentNode.handle) forKey:@"parentHandle"];
    [aCoder encodeObject:self.savedLocalIdentifier forKey:@"savedLocalIdentifier"];
    [aCoder encodeObject:@(self.encryptedChunksCount) forKey:@"encryptedChunksCount"];
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        _fileName = [aDecoder decodeObjectOfClass:NSString.class forKey:@"fileName"];
        _fileSize = [[aDecoder decodeObjectOfClass:NSNumber.class forKey:@"fileSize"] unsignedLongLongValue];
        _fingerprint = [aDecoder decodeObjectOfClass:NSString.class forKey:@"fingerprint"];
        _originalFingerprint = [aDecoder decodeObjectOfClass:NSString.class forKey:@"originalFingerprint"];
        _directoryURL = [aDecoder decodeObjectOfClass:NSURL.class forKey:@"directoryURL"];
        NSNumber *parentHandle = [aDecoder decodeObjectOfClass:NSNumber.class forKey:@"parentHandle"];
        _parentNode = [MEGASdkManager.sharedMEGASdk nodeForHandle:parentHandle.unsignedLongLongValue];
        NSData *serializedData = [aDecoder decodeObjectOfClass:NSData.class forKey:@"mediaUpload"];
        if (serializedData) {
            _mediaUpload = [MEGABackgroundMediaUpload unserializByData:serializedData MEGASdk:MEGASdkManager.sharedMEGASdk];
        }
        _savedLocalIdentifier = [aDecoder decodeObjectOfClass:NSString.class forKey:@"savedLocalIdentifier"];
        _encryptedChunksCount = [[aDecoder decodeObjectOfClass:NSNumber.class forKey:@"encryptedChunksCount"] unsignedIntegerValue];
    }
    
    return self;
}

@end
