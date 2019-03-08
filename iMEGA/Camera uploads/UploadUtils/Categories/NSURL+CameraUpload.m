
#import "NSURL+CameraUpload.h"
#import "NSString+MNZCategory.h"
#import "NSFileManager+MNZCategory.h"
#import "Helper.h"
@import AVFoundation;
@import CoreServices;

@implementation NSURL (CameraUpload)

+ (NSURL *)mnz_cameraUploadURL {
    NSURL *uploadURL = nil;
    NSURL *supportURL = [[NSFileManager.defaultManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] firstObject];
    if (supportURL) {
        NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
        uploadURL = [[supportURL URLByAppendingPathComponent:bundleId isDirectory:YES] URLByAppendingPathComponent:@"CameraUploads" isDirectory:YES];
        
        BOOL isDirectory = false;
        if(!([NSFileManager.defaultManager fileExistsAtPath:uploadURL.path isDirectory:&isDirectory] && isDirectory)) {
            NSError *error = nil;
            if (![NSFileManager.defaultManager createDirectoryAtURL:uploadURL withIntermediateDirectories:YES attributes:nil error:&error]) {
                MEGALogError(@"Create directory at url failed with error: %@", uploadURL);
                uploadURL = nil;
            }
            
            [uploadURL setResourceValue:@(YES) forKey:NSURLIsExcludedFromBackupKey error:nil];
        }
    }
    
    return uploadURL;
}

+ (NSURL *)mnz_assetDirectoryURLForLocalIdentifier:(NSString *)localIdentifier {
    return [self.mnz_cameraUploadURL URLByAppendingPathComponent:localIdentifier.mnz_stringByRemovingInvalidFileCharacters isDirectory:YES];
}

+ (NSURL *)mnz_archivedURLForLocalIdentifier:(NSString *)localIdentifier {
    return [[self mnz_assetDirectoryURLForLocalIdentifier:localIdentifier] URLByAppendingPathComponent:localIdentifier.mnz_stringByRemovingInvalidFileCharacters isDirectory:NO];
}

#pragma mark - create thumbnail for video

- (BOOL)mnz_exportVideoThumbnailToImageURL:(NSURL *)imageURL {
    BOOL isExportedSuccessfully = NO;
    
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:self options:nil];
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.appliesPreferredTrackTransform = YES;
    CMTime requestedTime = CMTimeMake(1, 60);
    NSError *error;
    CGImageRef imageRef = [generator copyCGImageAtTime:requestedTime actualTime:NULL error:&error];
    if (imageRef) {
        CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)imageURL, kUTTypeJPEG, 1, NULL);
        if (destination) {
            CGImageDestinationAddImage(destination, imageRef, NULL);
            isExportedSuccessfully = CGImageDestinationFinalize(destination);
            
            CFRelease(destination);
        }
        
        CGImageRelease(imageRef);
    } else {
        MEGALogError(@"error when to extract thumbnail image from video %@ %@", self, error);
    }
    
    return isExportedSuccessfully;
}

#pragma mark - thumbnail and preview caching

- (BOOL)mnz_moveToDirectory:(NSURL *)directoryURL renameTo:(NSString *)fileName {
    if (![NSFileManager.defaultManager fileExistsAtPath:self.path]) {
        return NO;
    }

    NSError *error;
    if ([NSFileManager.defaultManager createDirectoryAtURL:directoryURL withIntermediateDirectories:YES attributes:nil error:&error]) {
        NSURL *newFileURL = [directoryURL URLByAppendingPathComponent:fileName isDirectory:NO];
        [NSFileManager.defaultManager removeItemIfExistsAtURL:newFileURL];
        if ([NSFileManager.defaultManager moveItemAtURL:self toURL:newFileURL error:&error]) {
            return YES;
        } else {
            MEGALogError(@"%@ error %@ when to copy new file %@", self, error, newFileURL);
            return NO;
        }
    } else {
        MEGALogError(@"%@ error %@ when to create directory %@", self, error, directoryURL);
        return NO;
    }
}

- (BOOL)mnz_cacheThumbnailForNode:(MEGANode *)node {
    return [self mnz_moveToDirectory:[Helper urlForSharedSandboxCacheDirectory:@"thumbnailsV3"] renameTo:node.base64Handle];
}

- (BOOL)mnz_cachePreviewForNode:(MEGANode *)node {
    NSURL *cacheDirectory = [[NSFileManager.defaultManager URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] firstObject];
    return [self mnz_moveToDirectory:[cacheDirectory URLByAppendingPathComponent:@"previewsV3"] renameTo:node.base64Handle];
}



@end
