
#import "AttributeUploadManager.h"
#import "NSFileManager+MNZCategory.h"
#import "NSURL+CameraUpload.h"
#import "ThumbnailUploadOperation.h"
#import "PreviewUploadOperation.h"
#import "CoordinatesUploadOperation.h"
#import "CameraUploadManager.h"
#import "NSString+MNZCategory.h"
@import CoreLocation;

@interface AttributeUploadManager ()

@property (strong, nonatomic) NSOperationQueue *thumbnailOperationQueue;
@property (strong, nonatomic) NSOperationQueue *attributeOerationQueue;

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
        _thumbnailOperationQueue = [[NSOperationQueue alloc] init];
        _thumbnailOperationQueue.qualityOfService = NSQualityOfServiceUserInteractive;
        
        _attributeOerationQueue = [[NSOperationQueue alloc] init];
        _attributeOerationQueue.qualityOfService = NSQualityOfServiceUserInitiated;
    }
    return self;
}

#pragma mark - util

- (void)waitUntilAllThumbnailUploadsAreFinished {
    [self.thumbnailOperationQueue waitUntilAllOperationsAreFinished];
}

- (void)waitUntilAllAttributeUploadsAreFinished {
    [self waitUntilAllThumbnailUploadsAreFinished];
    [self.attributeOerationQueue waitUntilAllOperationsAreFinished];
}

#pragma mark - upload coordinate

- (void)uploadCoordinateLocation:(CLLocation *)location forNode:(MEGANode *)node {
    if (location == nil) {
        return;
    }
    
    [self.attributeOerationQueue addOperation:[[CoordinatesUploadOperation alloc] initWithLocation:location node:node]];
}

#pragma mark - upload preview and thumbnail files

- (AssetLocalAttribute *)saveAttributeForUploadInfo:(AssetUploadInfo *)uploadInfo {
    NSError *error;
    NSURL *attributeDirectoryURL = [self nodeAttributesDirectoryURLByLocalIdentifier:uploadInfo.savedLocalIdentifier];
    [NSFileManager.defaultManager removeItemIfExistsAtURL:attributeDirectoryURL];
    [NSFileManager.defaultManager createDirectoryAtURL:attributeDirectoryURL withIntermediateDirectories:YES attributes:nil error:&error];
    
    AssetLocalAttribute *attribute = [[AssetLocalAttribute alloc] initWithAttributeDirectoryURL:attributeDirectoryURL];
    [uploadInfo.fingerprint writeToURL:attribute.fingerprintURL atomically:YES encoding:NSUTF8StringEncoding error:&error];
    [NSFileManager.defaultManager copyItemAtURL:uploadInfo.thumbnailURL toURL:attribute.thumbnailURL error:&error];
    [NSFileManager.defaultManager copyItemAtURL:uploadInfo.previewURL toURL:attribute.previewURL error:&error];
    
    if (error) {
        MEGALogError(@"[Camera Upload] error when to save attributes for identifier %@ %@", uploadInfo.savedLocalIdentifier, error);
        return nil;
    }
    
    return attribute;
}

- (void)uploadLocalAttribute:(AssetLocalAttribute *)attribute forNode:(MEGANode *)node {
    if ([NSFileManager.defaultManager isReadableFileAtPath:attribute.thumbnailURL.path]) {
        [self.thumbnailOperationQueue addOperation:[[ThumbnailUploadOperation alloc] initWithAttributeURL:attribute.thumbnailURL node:node]];
    } else {
        MEGALogError(@"[Camera Upload] No thumbnail file found at URL %@", attribute.thumbnailURL);
    }
    
    if ([NSFileManager.defaultManager isReadableFileAtPath:attribute.previewURL.path]) {
        [self.attributeOerationQueue addOperation:[[PreviewUploadOperation alloc] initWithAttributeURL:attribute.previewURL node:node]];
    } else {
        MEGALogError(@"[Camera Upload] No preview file found at URL %@", attribute.previewURL);
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
        NSArray<NSURL *> *attributeDirectoryURLs = [NSFileManager.defaultManager contentsOfDirectoryAtURL:[self attributeDirectoryURL] includingPropertiesForKeys:nil options:NSDirectoryEnumerationSkipsHiddenFiles error:&error];
        if (error) {
            MEGALogError(@"[Camera Upload] error when to scan local attributes %@", error);
            return;
        }
        
        [MEGASdkManager.sharedMEGASdk retryPendingConnections];
        
        for (NSURL *URL in attributeDirectoryURLs) {
            [self scanAttributeDirectoryURL:URL];
        }
    });
}

- (void)scanAttributeDirectoryURL:(NSURL *)URL {
    AssetLocalAttribute *attribute = [[AssetLocalAttribute alloc] initWithAttributeDirectoryURL:URL];
    if (!attribute.hasAttributes) {
        [NSFileManager.defaultManager removeItemIfExistsAtURL:URL];
        return;
    }
    
    MEGANode *node = [MEGASdkManager.sharedMEGASdk nodeForFingerprint:attribute.savedFingerprint];
    if (node == nil) {
        MEGALogError(@"[Camera Upload] no node can be created from %@ for %@", attribute.savedFingerprint, URL.lastPathComponent);
        [NSFileManager.defaultManager removeItemIfExistsAtURL:URL];
        return;
    }
    
    [self retryUploadLocalAttribute:attribute forNode:node];
}

- (void)retryUploadLocalAttribute:(AssetLocalAttribute *)attribute forNode:(MEGANode *)node {
    if (attribute.hasSavedThumbnail) {
        if ([node hasThumbnail]) {
            [NSFileManager.defaultManager removeItemIfExistsAtURL:attribute.thumbnailURL];
        } else if (![self hasPendingAttributeOperationsForNode:node attributeType:MEGAAttributeTypeThumbnail]) {
            MEGALogDebug(@"[Camera Upload] retry thumbnail upload for %@", node.name);
            [self.thumbnailOperationQueue addOperation:[[ThumbnailUploadOperation alloc] initWithAttributeURL:attribute.thumbnailURL node:node]];
        }
    }
    
    if (attribute.hasSavedPreview) {
        if ([node hasPreview]) {
            [NSFileManager.defaultManager removeItemIfExistsAtURL:attribute.previewURL];
        } else if (![self hasPendingAttributeOperationsForNode:node attributeType:MEGAAttributeTypePreview]) {
            MEGALogDebug(@"[Camera Upload] retry preview upload for %@", node.name);
            [self.attributeOerationQueue addOperation:[[PreviewUploadOperation alloc] initWithAttributeURL:attribute.previewURL node:node]];
        }
    }
}

- (BOOL)hasPendingAttributeOperationsForNode:(MEGANode *)node attributeType:(MEGAAttributeType)type {
    BOOL hasPendingOperation = NO;
    
    if (type == MEGAAttributeTypeThumbnail) {
        for (NSOperation *operation in self.thumbnailOperationQueue.operations) {
            if ([operation isMemberOfClass:[ThumbnailUploadOperation class]]) {
                ThumbnailUploadOperation *thumbnailUploadOperation = (ThumbnailUploadOperation *)operation;
                if (thumbnailUploadOperation.node.handle == node.handle) {
                    hasPendingOperation = YES;
                    break;
                }
            }
        }
    } else if (type == MEGAAttributeTypePreview) {
        for (NSOperation *operation in self.attributeOerationQueue.operations) {
            if ([operation isMemberOfClass:[PreviewUploadOperation class]]) {
                PreviewUploadOperation *previewUploadOperation = (PreviewUploadOperation *)operation;
                if (previewUploadOperation.node.handle == node.handle) {
                    hasPendingOperation = YES;
                    break;
                }
            }
        }
    }
    
    return hasPendingOperation;
}

#pragma mark - Utils

- (NSURL *)attributeDirectoryURL {
    return [NSURL.mnz_cameraUploadURL URLByAppendingPathComponent:@"Attributes" isDirectory:YES];
}

- (NSURL *)nodeAttributesDirectoryURLByLocalIdentifier:(NSString *)identifier {
    return [[self attributeDirectoryURL] URLByAppendingPathComponent:identifier.mnz_stringByRemovingInvalidFileCharacters];
}

@end
