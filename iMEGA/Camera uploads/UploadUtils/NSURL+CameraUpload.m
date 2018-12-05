
#import "NSURL+CameraUpload.h"
#import "NSString+MNZCategory.h"

@implementation NSURL (CameraUpload)

+ (NSURL *)cameraUploadURL {
    NSURL *uploadURL = nil;
    NSURL *supportURL = [[NSFileManager.defaultManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] firstObject];
    if (supportURL) {
        NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
        uploadURL = [[supportURL URLByAppendingPathComponent:bundleId isDirectory:YES] URLByAppendingPathComponent:@"CameraUploads" isDirectory:YES];
        NSError *error = nil;
        if (![NSFileManager.defaultManager createDirectoryAtURL:uploadURL withIntermediateDirectories:YES attributes:nil error:&error]) {
            MEGALogError(@"Create directory at url failed with error: %@", uploadURL);
            return nil;
        }
        
        // TODO: exclude the path from iCloud backup/sync
    }
    
    return uploadURL;
}

+ (NSURL *)assetDirectoryURLForLocalIdentifier:(NSString *)localIdentifier {
    return [self.cameraUploadURL URLByAppendingPathComponent:localIdentifier.stringByRemovingInvalidFileCharacters isDirectory:YES];
}

+ (NSURL *)archivedURLForLocalIdentifier:(NSString *)localIdentifier {
    return [[self assetDirectoryURLForLocalIdentifier:localIdentifier] URLByAppendingPathComponent:localIdentifier.stringByRemovingInvalidFileCharacters isDirectory:NO];
}

@end
