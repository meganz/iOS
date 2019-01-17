
#import "NSURL+CameraUpload.h"
#import "NSString+MNZCategory.h"

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
    return [self.mnz_cameraUploadURL URLByAppendingPathComponent:localIdentifier.stringByRemovingInvalidFileCharacters isDirectory:YES];
}

+ (NSURL *)mnz_archivedURLForLocalIdentifier:(NSString *)localIdentifier {
    return [[self mnz_assetDirectoryURLForLocalIdentifier:localIdentifier] URLByAppendingPathComponent:localIdentifier.stringByRemovingInvalidFileCharacters isDirectory:NO];
}

@end
