#import "AssetLocalAttribute.h"

static NSString * const FingerprintFileName = @"fingerprint";

static NSString * const AttributeThumbnailName = @"thumbnail";
static NSString * const AttributePreviewName = @"preview";

@implementation AssetLocalAttribute

- (instancetype)initWithAttributeDirectoryURL:(NSURL *)URL {
    self = [super init];
    if (self) {
        _attributeDirectoryURL = URL;
    }
    return self;
}

- (NSURL *)fingerprintURL {
    return [self.attributeDirectoryURL URLByAppendingPathComponent:FingerprintFileName isDirectory:NO];
}

- (NSString *)savedFingerprint {
    return [NSString stringWithContentsOfURL:self.fingerprintURL encoding:NSUTF8StringEncoding error:nil];
}

- (NSURL *)previewURL {
    return [self.attributeDirectoryURL URLByAppendingPathComponent:AttributePreviewName isDirectory:NO];
}

- (BOOL)hasSavedPreview {
    BOOL isDirectory;
    return [NSFileManager.defaultManager fileExistsAtPath:self.previewURL.path isDirectory:&isDirectory] && !isDirectory;
}

- (NSURL *)thumbnailURL {
    return [self.attributeDirectoryURL URLByAppendingPathComponent:AttributeThumbnailName isDirectory:NO];
}

- (BOOL)hasSavedThumbnail {
    BOOL isDirectory;
    return [NSFileManager.defaultManager fileExistsAtPath:self.thumbnailURL.path isDirectory:&isDirectory] && !isDirectory;
}

- (BOOL)hasSavedAttributes {
    NSArray<NSString *> *contents = [NSFileManager.defaultManager contentsOfDirectoryAtPath:self.attributeDirectoryURL.path error:nil];
    if (contents.count == 0) {
        return NO;
    } else if (contents.count == 1 && [contents.firstObject isEqualToString:FingerprintFileName]) {
        return NO;
    } else {
        return YES;
    }
}

@end
