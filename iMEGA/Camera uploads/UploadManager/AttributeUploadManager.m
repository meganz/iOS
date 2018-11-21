
#import "AttributeUploadManager.h"
#import "NSFileManager+MNZCategory.h"
#import "ThumbnailUploadOperation.h"
#import "PreviewUploadOperation.h"

@implementation AttributeUploadManager

+ (instancetype)shared {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

- (void)uploadAttributeAtURL:(NSURL *)URL withAttributeType:(MEGAAttributeType)type forNode:(MEGANode *)node {
    if (![NSFileManager.defaultManager fileExistsAtPath:URL.path]) {
        MEGALogDebug(@"[Camera Upload] No attribute file found for node %@ at URL: %@", node.name, URL);
        return;
    }
    
    NSURL *uploadURL = [self attributeUploadURLForAttributeType:type node:node];
    
    NSError *error;
    [NSFileManager.defaultManager copyItemAtURL:URL toURL:uploadURL error:&error];
    if (error) {
        MEGALogDebug(@"[Camera Upload] Error when to copy attribute file to %@ %@", uploadURL, error);
        return;
    }
    
    switch (type) {
        case MEGAAttributeTypeThumbnail:
            [self.operationQueue addOperation:[[ThumbnailUploadOperation alloc] initWithAttributeURL:URL node:node expiresAfterTimeInterval:90]];
            break;
        case MEGAAttributeTypePreview:
            [self.operationQueue addOperation:[[PreviewUploadOperation alloc] initWithAttributeURL:URL node:node expiresAfterTimeInterval:90]];
            break;
        default:
            break;
    }
}

- (NSURL *)attributeUploadURLForAttributeType:(MEGAAttributeType)type node:(MEGANode *)node  {
    NSString *attributeName;
    switch (type) {
        case MEGAAttributeTypeThumbnail:
            attributeName = @"thumbnail";
            break;
        case MEGAAttributeTypePreview:
            attributeName = @"preview";
            break;
        default:
            return nil;
            break;
    }
    
    NSURL *uploadURL = [[[self attributeDirectoryURL] URLByAppendingPathComponent:node.base64Handle] URLByAppendingPathComponent:attributeName isDirectory:NO];
    [NSFileManager.defaultManager removeItemIfExistsAtURL:uploadURL];
    [NSFileManager.defaultManager createDirectoryAtURL:uploadURL withIntermediateDirectories:YES attributes:nil error:nil];
    return uploadURL;
}

- (NSURL *)attributeDirectoryURL {
    return [NSFileManager.defaultManager.cameraUploadURL URLByAppendingPathComponent:@"Attributes" isDirectory:YES];
}

@end
