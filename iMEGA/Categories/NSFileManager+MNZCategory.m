
#import "NSFileManager+MNZCategory.h"

@implementation NSFileManager (MNZCategory)

- (NSString *)downloadsDirectory {
    NSString *downloadsDirectory = [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"Downloads"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:downloadsDirectory]) {
        NSError *error = nil;
        if (![[NSFileManager defaultManager] createDirectoryAtPath:downloadsDirectory withIntermediateDirectories:YES attributes:nil error:&error]) {
            MEGALogError(@"Create directory at path failed with error: %@", error);
        }
    }
    
    return downloadsDirectory;
}

- (NSString *)uploadsDirectory {
    NSString *uploadsDirectory = [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"Uploads"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:uploadsDirectory]) {
        NSError *error = nil;
        if (![[NSFileManager defaultManager] createDirectoryAtPath:uploadsDirectory withIntermediateDirectories:YES attributes:nil error:&error]) {
            MEGALogError(@"Create directory at path failed with error: %@", error);
        }
    }
    
    return uploadsDirectory;
}

- (NSURL *)cameraUploadURL {
    NSURL *uploadURL = nil;
    NSURL *supportURL = [[self URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] firstObject];
    if (supportURL) {
        NSString *bundleId = [[NSBundle mainBundle] bundleIdentifier];
        uploadURL = [[supportURL URLByAppendingPathComponent:bundleId isDirectory:YES] URLByAppendingPathComponent:@"CameraUploads" isDirectory:YES];
        NSError *error = nil;
        if (![self createDirectoryAtURL:uploadURL withIntermediateDirectories:YES attributes:nil error:&error]) {
            MEGALogError(@"Create directory at url failed with error: %@", uploadURL);
            return nil;
        }
        
        // TODO: exclude the path from iCloud backup/sync
    }
    
    return uploadURL;
}

- (void)removeItemIfExistsAtURL:(NSURL *)URL {
    if ([self fileExistsAtPath:URL.path]) {
        NSError *removeFileError;
        [self removeItemAtURL:URL error:&removeFileError];
        if (removeFileError) {
            MEGALogDebug(@"Error when to remove existing file %@, error detail: %@", URL, removeFileError);
        }
    }
}

- (unsigned long long)deviceFreeSize {
    return [[self attributesOfFileSystemForPath:NSHomeDirectory() error:nil][NSFileSystemFreeSize] unsignedLongLongValue];
}

@end
