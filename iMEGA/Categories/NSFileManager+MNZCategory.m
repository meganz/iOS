
#import "NSFileManager+MNZCategory.h"

@implementation NSFileManager (MNZCategory)

#pragma mark - Paths

- (NSString *)downloadsDirectory {
    NSString *downloadsDirectory = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"Downloads"];
    if (![self fileExistsAtPath:downloadsDirectory]) {
        NSError *error = nil;
        if (![self createDirectoryAtPath:downloadsDirectory withIntermediateDirectories:YES attributes:nil error:&error]) {
            MEGALogError(@"Create directory at path failed with error: %@", error);
        }
    }
    
    return downloadsDirectory;
}

- (NSString *)uploadsDirectory {
    NSString *uploadsDirectory = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"Uploads"];
    if (![self fileExistsAtPath:uploadsDirectory]) {
        NSError *error = nil;
        if (![self createDirectoryAtPath:uploadsDirectory withIntermediateDirectories:YES attributes:nil error:&error]) {
            MEGALogError(@"Create directory at path failed with error: %@", error);
        }
    }
    
    return uploadsDirectory;
}

#pragma mark - Manage files and folders

- (unsigned long long)mnz_sizeOfFolderAtPath:(NSString *)path {
    unsigned long long folderSize = 0;
    
    NSArray *directoryContents = [self contentsOfDirectoryAtPath:path error:nil];
    for (NSString *item in directoryContents) {
        NSDictionary *attributesDictionary = [self attributesOfItemAtPath:[path stringByAppendingPathComponent:item] error:nil];
        if (attributesDictionary[NSFileType] == NSFileTypeDirectory) {
            folderSize += [self mnz_sizeOfFolderAtPath:[path stringByAppendingPathComponent:item]];
        } else {
            folderSize += [attributesDictionary[NSFileSize] unsignedLongLongValue];
        }
    }
    
    return folderSize;
}

- (unsigned long long)mnz_groupSharedDirectorySize {
    //We avoid calculation the space of the whole shared directory 'group.mega.ios' because there is always a plist file there and that will cause that after tapping on 'Clear cache' the footer show that some space is being used.
    NSString *groupSharedDirectoryPath = [self containerURLForSecurityApplicationGroupIdentifier:MEGAGroupIdentifier].path;
    unsigned long long logs = [self mnz_sizeOfFolderAtPath:[groupSharedDirectoryPath stringByAppendingPathComponent:MEGAExtensionLogsFolder]];
    unsigned long long fileProviderStorage = [self mnz_sizeOfFolderAtPath:[groupSharedDirectoryPath stringByAppendingPathComponent:MEGAFileExtensionStorageFolder]];
    unsigned long long shareExtensionStorage = [self mnz_sizeOfFolderAtPath:[groupSharedDirectoryPath stringByAppendingPathComponent:MEGAShareExtensionStorageFolder]];
    
    return (logs + fileProviderStorage + shareExtensionStorage);
}

- (void)mnz_removeItemAtPath:(NSString *)path {
    if (path == nil) {
        MEGALogError(@"The path to remove the item is nil.");
        return;
    }
    
    NSError *error = nil;
    if ([self removeItemAtPath:path error:&error]) {
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
    NSArray *directoryContentsArray = [self contentsOfDirectoryAtPath:folderPath error:nil];
    for (NSString *itemName in directoryContentsArray) {
        [self mnz_removeItemAtPath:[folderPath stringByAppendingPathComponent:itemName]];
    }
}

- (void)mnz_removeFolderContentsAtPath:(NSString *)folderPath forItemsContaining:(NSString *)itemsContaining {
    NSArray *directoryContentsArray = [self contentsOfDirectoryAtPath:folderPath error:nil];
    for (NSString *itemName in directoryContentsArray) {
        if ([itemName.lowercaseString containsString:itemsContaining]) {
            [self mnz_removeItemAtPath:[folderPath stringByAppendingPathComponent:itemName]];
        }
    }
}

- (void)mnz_removeFolderContentsRecursivelyAtPath:(NSString *)folderPath forItemsContaining:(NSString *)itemsContaining {
    NSArray *directoryContentsArray = [self contentsOfDirectoryAtPath:folderPath error:nil];
    for (NSString *itemName in directoryContentsArray) {
        NSDictionary *attributesDictionary = [self attributesOfItemAtPath:[folderPath stringByAppendingPathComponent:itemName] error:nil];
        if ([attributesDictionary objectForKey:NSFileType] == NSFileTypeDirectory) {
            [self mnz_removeFolderContentsRecursivelyAtPath:[folderPath stringByAppendingPathComponent:itemName] forItemsContaining:itemsContaining];
        } else {
            if ([itemName.lowercaseString containsString:itemsContaining]) {
                [self mnz_removeItemAtPath:[folderPath stringByAppendingPathComponent:itemName]];
            }
        }
    }
}

- (void)mnz_removeFolderContentsRecursivelyAtPath:(NSString *)folderPath forItemsExtension:(NSString *)itemsExtension {
    NSArray *directoryContentsArray = [self contentsOfDirectoryAtPath:folderPath error:nil];
    NSString *currentPath = folderPath;
    NSEnumerator *enumerator = [directoryContentsArray objectEnumerator];
    NSMutableArray *stack = [NSMutableArray array];
    
    if (enumerator) {
        [stack addObject:enumerator];
    }
    
    /*
     Using Stack Depth-First-Search(DFS) to replace normal recursion
     Memory allocation can't be released asap in normal recursion way, so
     here is using local stack to maintain enumerators(pointers) to avoid
     high space complexity.
     */
    while([stack count] > 0) {
        NSEnumerator *top = stack.lastObject;
        NSString *fileName = [top nextObject];
        
        if (fileName) {
            NSDictionary *attributesDictionary = [self attributesOfItemAtPath:[currentPath stringByAppendingPathComponent:fileName] error:nil];
            
            if ([attributesDictionary objectForKey:NSFileType] == NSFileTypeDirectory) {
                currentPath = [currentPath stringByAppendingPathComponent:fileName];
                NSArray *contents = [self contentsOfDirectoryAtPath: currentPath error:nil];
                NSEnumerator *enumerator = [contents objectEnumerator];
                
                if (enumerator) {
                    [stack addObject:enumerator];
                }
            } else {
                if ([fileName.pathExtension.lowercaseString isEqualToString:itemsExtension]) {
                    [self mnz_removeItemAtPath:[currentPath stringByAppendingPathComponent:fileName]];
                }
            }
        } else {
            NSArray *contents = [self contentsOfDirectoryAtPath:currentPath error:nil];
            
            if (contents.count == 0 && currentPath != folderPath) {
                [self mnz_removeItemAtPath:currentPath];
            }
            
            currentPath = [currentPath stringByDeletingLastPathComponent];
            [stack removeLastObject];
        }
    }
}

- (void)mnz_moveItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath {
    if (srcPath == nil || dstPath == nil) {
        MEGALogError(@"Source path (%@) or destination path (%@) nil.", srcPath, dstPath);
        return;
    }
    
    NSError *error = nil;
    if ([self moveItemAtPath:srcPath toPath:dstPath error:&error]) {
        MEGALogInfo(@"Move item succeed:\n- At path: %@\n- To path: %@", srcPath, dstPath);
    } else if (error) {
        MEGALogError(@"Move item failed:\n- At path: %@\n- To path: %@\n- With error: %@", srcPath, dstPath, error);
    }
}

#pragma mark - Properties

- (uint64_t)mnz_fileSystemFreeSizeWithError:(NSError *)error {
    uint64_t totalFreeSpace = 0;
    NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:NSHomeDirectory()];
    NSDictionary *results = [fileURL resourceValuesForKeys:@[NSURLVolumeAvailableCapacityForImportantUsageKey] error:&error];
    if (!results) {
        MEGALogError(@"Error Obtaining System Memory Info: Domain = %@, Code = %ld", [error domain], (long)[error code]);
    } else {
        MEGALogDebug(@"Available capacity for important usage: %@", results[NSURLVolumeAvailableCapacityForImportantUsageKey]);
        totalFreeSpace = ((NSString *)results[NSURLVolumeAvailableCapacityForImportantUsageKey]).longLongValue;
        return totalFreeSpace;
    }
    
    NSDictionary *attributesOfHomeDirectoryDictionary = [self attributesOfFileSystemForPath:NSHomeDirectory() error:&error];
    if (attributesOfHomeDirectoryDictionary) {
        NSNumber *fileSystemFreeSizeInBytes = [attributesOfHomeDirectoryDictionary objectForKey:NSFileSystemFreeSize];
        return fileSystemFreeSizeInBytes.unsignedLongLongValue;
    } else {
        MEGALogError(@"Obtaining attributes of home directory failed with error: %@", error);
    }
    
    return 0;
}

- (UInt64)mnz_fileSystemFreeSize {
    return [self mnz_fileSystemFreeSizeWithError:nil];
}

#pragma mark - Utils

- (BOOL)mnz_existsOfflineFiles {
    NSError *error;
    NSArray *directoryContent = [self contentsOfDirectoryAtPath:NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject error:&error];
    if (error) {
        MEGALogError(@"Contents of directory at path failed with error: %@", error);
    }
    
    BOOL isInboxDirectory = NO;
    for (NSString *directoryElement in directoryContent) {
        if ([directoryElement isEqualToString:@"Inbox"]) {
            NSString *inboxPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"/Inbox"];
            [self fileExistsAtPath:inboxPath isDirectory:&isInboxDirectory];
            break;
        }
    }
    
    if (directoryContent.count == 0 || (directoryContent.count == 1 && isInboxDirectory)) {
        return NO;
    } else {
        for (int i = 0; i < directoryContent.count; i++) {
            NSString *fileName = [NSString stringWithFormat:@"%@", [directoryContent objectAtIndex:i]];
            if (![fileName.lowercaseString.pathExtension isEqualToString:@"mega"]) {
                return YES;
            }
        }
        return NO;
    }
}

@end
