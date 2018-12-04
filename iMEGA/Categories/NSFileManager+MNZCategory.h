
#import <Foundation/Foundation.h>

@interface NSFileManager (MNZCategory)

#pragma mark - Paths

- (NSString *)downloadsDirectory;
- (NSString *)uploadsDirectory;

#pragma mark - Remove files and folders

- (void)mnz_removeItemAtPath:(NSString *)path;
- (void)mnz_removeFolderContentsAtPath:(NSString *)folderPath;
- (void)mnz_removeFolderContentsAtPath:(NSString *)folderPath forItemsContaining:(NSString *)filesContaining;
- (void)mnz_removeFolderContentsRecursivelyAtPath:(NSString *)folderPath forItemsContaining:(NSString *)itemsContaining;
- (void)mnz_removeFolderContentsRecursivelyAtPath:(NSString *)folderPath forItemsExtension:(NSString *)itemsExtension;

#pragma mark - URL based file management

/**
 Remove a file or directory if it exists at the given URL

 @param URL file or directory URL
 */
- (void)removeItemIfExistsAtURL:(NSURL *)URL;


/**
 Get the free space of the device

 @return the free size of the device in bytes.
 */
- (unsigned long long)deviceFreeSize;

@end
