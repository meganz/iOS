
#import <Foundation/Foundation.h>

@interface NSFileManager (MNZCategory)

/**
 amount of free space on the file system in bytes
 */
@property (readonly) unsigned long long mnz_fileSystemFreeSize;

#pragma mark - Paths

- (NSString *)downloadsDirectory;
- (NSString *)uploadsDirectory;

#pragma mark - Manage files and folders

- (unsigned long long)mnz_sizeOfFolderAtPath:(NSString *)path;

- (unsigned long long)mnz_groupSharedDirectorySize;

- (void)mnz_removeItemAtPath:(NSString *)path;
- (void)mnz_removeFolderContentsAtPath:(NSString *)folderPath;
- (void)mnz_removeFolderContentsAtPath:(NSString *)folderPath forItemsContaining:(NSString *)filesContaining;
- (void)mnz_removeFolderContentsRecursivelyAtPath:(NSString *)folderPath forItemsContaining:(NSString *)itemsContaining;
- (void)mnz_removeFolderContentsRecursivelyAtPath:(NSString *)folderPath forItemsExtension:(NSString *)itemsExtension;

- (void)mnz_moveItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath;

@end
