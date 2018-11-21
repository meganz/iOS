
#import "AttributeUploadManager.h"
#import "NSFileManager+MNZCategory.h"
#import "ThumbnailUploadOperation.h"
#import "PreviewUploadOperation.h"

static NSString * const AttributeThumbnailName = @"thumbnail";
static NSString * const AttributePreviewName = @"preview";

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

#pragma mark - attributes scan and retry

- (void)scanLocalAttributesAndRetryUploadIfNeeded {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error;
        NSArray *resourceKeys = @[NSURLIsDirectoryKey, NSURLNameKey];
        NSArray<NSURL *> *attributeDirectoryURLs = [NSFileManager.defaultManager contentsOfDirectoryAtURL:[self attributeDirectoryURL] includingPropertiesForKeys:resourceKeys options:NSDirectoryEnumerationSkipsHiddenFiles error:&error];
        if (error) {
            MEGALogDebug(@"[Camera Upload] error when to scan local attributes %@", error);
            return;
        }
        
        for (NSURL *URL in attributeDirectoryURLs) {
            NSDictionary *resourceValueDict = [URL resourceValuesForKeys:resourceKeys error:nil];
            if ([resourceValueDict[NSURLIsDirectoryKey] boolValue]) {
                [self scanAttributeDirectoryURL:URL directoryName:resourceValueDict[NSURLNameKey]];
            }
        }
    });
}

- (void)scanAttributeDirectoryURL:(NSURL *)URL directoryName:(NSString *)name {
    NSError *error;
    NSArray *resourceKeys = @[NSURLIsDirectoryKey, NSURLNameKey];
    NSArray<NSURL *> *attributeURLs = [NSFileManager.defaultManager contentsOfDirectoryAtURL:URL includingPropertiesForKeys:resourceKeys options:NSDirectoryEnumerationSkipsHiddenFiles error:&error];
    if (error) {
        MEGALogDebug(@"[Camera Upload] error when to scan attribute directory %@ %@", URL, error);
        return;
    }
    
    if (attributeURLs.count == 0) {
        [NSFileManager.defaultManager removeItemIfExistsAtURL:URL];
        return;
    }
    
    MEGANode *node = [MEGASdkManager.sharedMEGASdk nodeForHandle:[MEGASdk handleForBase64Handle:name]];
    if (node == nil) {
        [NSFileManager.defaultManager removeItemIfExistsAtURL:URL];
        return;
    }
    
    for (NSURL *URL in attributeURLs) {
        NSDictionary *resourceValueDict = [URL resourceValuesForKeys:resourceKeys error:nil];
        if (![resourceValueDict[NSURLIsDirectoryKey] boolValue]) {
            NSString *fileName = resourceValueDict[NSURLNameKey];
            [self retryAttributeUploadIfNeededForNode:node attributeAtURL:URL attributeName:fileName];
        }
    }
}

- (void)retryAttributeUploadIfNeededForNode:(MEGANode *)node attributeAtURL:(NSURL *)URL attributeName:(NSString *)name {
    if ([name isEqualToString:AttributeThumbnailName]) {
        if ([node hasThumbnail]) {
            [NSFileManager.defaultManager removeItemIfExistsAtURL:URL];
        } else {
            [self.operationQueue addOperation:[[ThumbnailUploadOperation alloc] initWithAttributeURL:URL node:node expiresAfterTimeInterval:90]];
        }
    } else if ([name isEqualToString:AttributePreviewName]) {
        if ([node hasPreview]) {
            [NSFileManager.defaultManager removeItemIfExistsAtURL:URL];
        } else {
            [self.operationQueue addOperation:[[PreviewUploadOperation alloc] initWithAttributeURL:URL node:node expiresAfterTimeInterval:90]];
        }
    }
}

#pragma mark - URLs for attributes

- (NSURL *)attributeUploadURLForAttributeType:(MEGAAttributeType)type node:(MEGANode *)node  {
    NSString *attributeName;
    switch (type) {
        case MEGAAttributeTypeThumbnail:
            attributeName = AttributeThumbnailName;
            break;
        case MEGAAttributeTypePreview:
            attributeName = AttributePreviewName;
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
