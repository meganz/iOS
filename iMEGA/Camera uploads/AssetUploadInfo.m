
#import "AssetUploadInfo.h"

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

@end
