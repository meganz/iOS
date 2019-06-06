
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
        _fileName = [aDecoder decodeObjectForKey:@"fileName"];
        _fileSize = [[aDecoder decodeObjectForKey:@"fileSize"] unsignedLongLongValue];
        _fingerprint = [aDecoder decodeObjectForKey:@"fingerprint"];
        _originalFingerprint = [aDecoder decodeObjectForKey:@"originalFingerprint"];
        _directoryURL = [aDecoder decodeObjectForKey:@"directoryURL"];
        _parentNode = [MEGASdkManager.sharedMEGASdk nodeForHandle:[[aDecoder decodeObjectForKey:@"parentHandle"] unsignedLongLongValue]];
        NSData *serializedData = [aDecoder decodeObjectForKey:@"mediaUpload"];
        _mediaUpload = [MEGABackgroundMediaUpload unserializByData:serializedData MEGASdk:MEGASdkManager.sharedMEGASdk];
        _savedLocalIdentifier = [aDecoder decodeObjectForKey:@"savedLocalIdentifier"];
        _encryptedChunksCount = [[aDecoder decodeObjectForKey:@"encryptedChunksCount"] unsignedIntegerValue];
    }
    
    return self;
}

@end
