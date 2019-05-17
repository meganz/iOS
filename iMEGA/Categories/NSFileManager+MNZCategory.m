
#import "NSFileManager+MNZCategory.h"

@implementation NSFileManager (MNZCategory)

#pragma mark - Paths

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

#pragma mark - Manage files and folders

- (void)mnz_removeItemAtPath:(NSString *)path {
    if (path == nil) {
        MEGALogError(@"The path to remove the item is nil.");
        return;
    }
    
    NSError *error = nil;
    if ([NSFileManager.defaultManager removeItemAtPath:path error:&error]) {
        MEGALogInfo(@"Remove item at path succeed:\n- At path: %@", path);
    } else {
        if ([error.domain isEqualToString:NSCocoaErrorDomain]) {
            switch (error.code) {
                case NSFileNoSuchFileError:
                    MEGALogError(@"Remove item operation attempted on non-existent file:\n- At path: %@", path);
                    break;
                    
                default:
                    MEGALogError(@"Remove item failed:\n- At path: %@\n- With error: %@", path, error);
                    break;
            }
        }
    }
}

- (void)mnz_removeFolderContentsAtPath:(NSString *)folderPath {
    NSArray *directoryContentsArray = [NSFileManager.defaultManager contentsOfDirectoryAtPath:folderPath error:nil];
    for (NSString *itemName in directoryContentsArray) {
        [NSFileManager.defaultManager mnz_removeItemAtPath:[folderPath stringByAppendingPathComponent:itemName]];
    }
}

- (void)mnz_removeFolderContentsAtPath:(NSString *)folderPath forItemsContaining:(NSString *)itemsContaining {
    NSArray *directoryContentsArray = [NSFileManager.defaultManager contentsOfDirectoryAtPath:folderPath error:nil];
    for (NSString *itemName in directoryContentsArray) {
        if ([itemName.lowercaseString containsString:itemsContaining]) {
            [NSFileManager.defaultManager mnz_removeItemAtPath:[folderPath stringByAppendingPathComponent:itemName]];
        }
    }
}

- (void)mnz_removeFolderContentsRecursivelyAtPath:(NSString *)folderPath forItemsContaining:(NSString *)itemsContaining {
    NSArray *directoryContentsArray = [NSFileManager.defaultManager contentsOfDirectoryAtPath:folderPath error:nil];
    for (NSString *itemName in directoryContentsArray) {
        NSDictionary *attributesDictionary = [NSFileManager.defaultManager attributesOfItemAtPath:[folderPath stringByAppendingPathComponent:itemName] error:nil];
        if ([attributesDictionary objectForKey:NSFileType] == NSFileTypeDirectory) {
            [NSFileManager.defaultManager mnz_removeFolderContentsRecursivelyAtPath:[folderPath stringByAppendingPathComponent:itemName] forItemsContaining:itemsContaining];
        } else {
            if ([itemName.lowercaseString containsString:itemsContaining]) {
                [NSFileManager.defaultManager mnz_removeItemAtPath:[folderPath stringByAppendingPathComponent:itemName]];
            }
        }
    }
}

- (void)mnz_removeFolderContentsRecursivelyAtPath:(NSString *)folderPath forItemsExtension:(NSString *)itemsExtension {
    NSArray *directoryContentsArray = [NSFileManager.defaultManager contentsOfDirectoryAtPath:folderPath error:nil];
    for (NSString *itemName in directoryContentsArray) {
        NSDictionary *attributesDictionary = [NSFileManager.defaultManager attributesOfItemAtPath:[folderPath stringByAppendingPathComponent:itemName] error:nil];
        if ([attributesDictionary objectForKey:NSFileType] == NSFileTypeDirectory) {
            [NSFileManager.defaultManager mnz_removeFolderContentsRecursivelyAtPath:[folderPath stringByAppendingPathComponent:itemName] forItemsExtension:itemsExtension];
        } else {
            if ([itemName.pathExtension.lowercaseString isEqualToString:itemsExtension]) {
                [NSFileManager.defaultManager mnz_removeItemAtPath:[folderPath stringByAppendingPathComponent:itemName]];
            }
        }
    }
}

#pragma mark - properties

- (unsigned long long)deviceFreeSize {
    return [[self attributesOfFileSystemForPath:NSHomeDirectory() error:nil][NSFileSystemFreeSize] unsignedLongLongValue];
}

@end
