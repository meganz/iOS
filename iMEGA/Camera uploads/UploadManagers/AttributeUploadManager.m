
#import "AttributeUploadManager.h"
#import "NSFileManager+MNZCategory.h"
#import "NSURL+CameraUpload.h"
#import "ThumbnailUploadOperation.h"
#import "PreviewUploadOperation.h"
#import "CoordinatesUploadOperation.h"
#import "CameraUploadManager.h"
@import CoreLocation;

static NSString * const AttributeThumbnailName = @"thumbnail";
static NSString * const AttributePreviewName = @"preview";
static const NSTimeInterval AttributeUploadExpireTimeInterval = 90;

@interface AttributeUploadManager ()

@property (strong, nonatomic) NSOperationQueue *operationQueue;

@end

@implementation AttributeUploadManager

+ (instancetype)shared {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.qualityOfService = NSQualityOfServiceUtility;
    }
    return self;
}

#pragma mark - util

- (void)waitUnitlAllAttributeUploadsAreFinished {
    [self.operationQueue waitUntilAllOperationsAreFinished];
}

#pragma mark - upload coordinate

- (void)uploadCoordinateAtLocation:(CLLocation *)location forNode:(MEGANode *)node {
    [self.operationQueue addOperation:[[CoordinatesUploadOperation alloc] initWithLocation:location node:node expiresAfterTimeInterval:AttributeUploadExpireTimeInterval]];
}

#pragma mark - upload preview and thumbnail files

- (void)uploadFileAtURL:(NSURL *)URL withAttributeType:(MEGAAttributeType)type forNode:(MEGANode *)node {
    if (![NSFileManager.defaultManager isReadableFileAtPath:URL.path]) {
        return;
    }
    
    NSURL *uploadURL = [self attributeUploadURLForAttributeType:type node:node];
    
    NSError *error;
    [NSFileManager.defaultManager copyItemAtURL:URL toURL:uploadURL error:&error];
    if (error) {
        MEGALogError(@"[Camera Upload] error when to copy attribute file to %@, error: %@", uploadURL, error);
        return;
    }
    
    switch (type) {
        case MEGAAttributeTypeThumbnail:
            [self.operationQueue addOperation:[[ThumbnailUploadOperation alloc] initWithAttributeURL:uploadURL node:node expiresAfterTimeInterval:AttributeUploadExpireTimeInterval]];
            break;
        case MEGAAttributeTypePreview:
            [self.operationQueue addOperation:[[PreviewUploadOperation alloc] initWithAttributeURL:uploadURL node:node expiresAfterTimeInterval:AttributeUploadExpireTimeInterval]];
            break;
        default:
            break;
    }
}

#pragma mark - attributes scan and retry

- (void)scanLocalAttributeFilesAndRetryUploadIfNeeded {
    if (!(MEGASdkManager.sharedMEGASdk.isLoggedIn && CameraUploadManager.shared.isNodesFetchDone)) {
        return;
    }
    
    MEGALogDebug(@"[Camera Upload] scan local attribute files and retry upload");
    
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        if (![NSFileManager.defaultManager fileExistsAtPath:[self attributeDirectoryURL].path]) {
            return;
        }
        
        NSError *error;
        NSArray *resourceKeys = @[NSURLIsDirectoryKey, NSURLNameKey];
        NSArray<NSURL *> *attributeDirectoryURLs = [NSFileManager.defaultManager contentsOfDirectoryAtURL:[self attributeDirectoryURL] includingPropertiesForKeys:resourceKeys options:NSDirectoryEnumerationSkipsHiddenFiles error:&error];
        if (error) {
            MEGALogError(@"[Camera Upload] error when to scan local attributes %@", error);
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
        MEGALogError(@"[Camera Upload] error when to scan attribute directory %@ %@", URL, error);
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
            [self.operationQueue addOperation:[[ThumbnailUploadOperation alloc] initWithAttributeURL:URL node:node expiresAfterTimeInterval:AttributeUploadExpireTimeInterval]];
        }
    } else if ([name isEqualToString:AttributePreviewName]) {
        if ([node hasPreview]) {
            [NSFileManager.defaultManager removeItemIfExistsAtURL:URL];
        } else {
            [self.operationQueue addOperation:[[PreviewUploadOperation alloc] initWithAttributeURL:URL node:node expiresAfterTimeInterval:AttributeUploadExpireTimeInterval]];
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
    
    NSURL *nodeDirectoryURL = [[self attributeDirectoryURL] URLByAppendingPathComponent:node.base64Handle];
    [NSFileManager.defaultManager createDirectoryAtURL:nodeDirectoryURL withIntermediateDirectories:YES attributes:nil error:nil];
    
    NSURL *uploadURL = [nodeDirectoryURL URLByAppendingPathComponent:attributeName isDirectory:NO];
    [NSFileManager.defaultManager removeItemIfExistsAtURL:uploadURL];
    
    return uploadURL;
}

- (NSURL *)attributeDirectoryURL {
    return [NSURL.mnz_cameraUploadURL URLByAppendingPathComponent:@"Attributes" isDirectory:YES];
}

@end
