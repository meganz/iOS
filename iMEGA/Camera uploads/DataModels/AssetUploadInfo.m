
#import "AssetUploadInfo.h"
#import "CameraUploadManager.h"

@implementation AssetUploadInfo

#pragma mark - init

- (instancetype)initWithAsset:(PHAsset *)asset parentNode:(MEGANode *)parentNode {
    self = [super init];
    if (self) {
        _asset = asset;
        _parentNode = parentNode;
        _location = asset.location;
    }
    return self;
}

#pragma mark - properties

- (NSURL *)fileURL {
    return [self.directoryURL URLByAppendingPathComponent:self.fileName];
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
    [aCoder encodeObject:self.location forKey:@"location"];
    [aCoder encodeObject:self.fingerprint forKey:@"fingerprint"];
    [aCoder encodeObject:self.originalFingerprint forKey:@"originalFingerprint"];
    [aCoder encodeObject:self.directoryURL forKey:@"directoryURL"];
    [aCoder encodeObject:self.mediaUpload.serialize forKey:@"mediaUpload"];
    [aCoder encodeObject:@(self.parentNode.handle) forKey:@"parentHandle"];
}

- (nullable instancetype)initWithCoder:(nonnull NSCoder *)aDecoder {
    self = [super init];
    if (self) {
        _fileName = [aDecoder decodeObjectForKey:@"fileName"];
        _fileSize = [[aDecoder decodeObjectForKey:@"fileSize"] unsignedLongLongValue];
        _location = [aDecoder decodeObjectForKey:@"location"];
        _fingerprint = [aDecoder decodeObjectForKey:@"fingerprint"];
        _originalFingerprint = [aDecoder decodeObjectForKey:@"originalFingerprint"];
        _directoryURL = [aDecoder decodeObjectForKey:@"directoryURL"];
        _parentNode = [MEGASdkManager.sharedMEGASdk nodeForHandle:[[aDecoder decodeObjectForKey:@"parentHandle"] unsignedLongLongValue]];
        if (_parentNode == nil) {
            _parentNode = [CameraUploadManager.shared cameraUploadNode];
        }
        NSData *serializedData = [aDecoder decodeObjectForKey:@"mediaUpload"];
        _mediaUpload = [[MEGASdkManager sharedMEGASdk] resumeBackgroundMediaUploadBySerializedData:serializedData];
    }
    
    return self;
}

@end
