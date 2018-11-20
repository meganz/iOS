
#import <Foundation/Foundation.h>

@interface NSFileManager (MNZCategory)

- (NSString *)downloadsDirectory;
- (NSString *)uploadsDirectory;

/**
 A pre-defined URL for camera upload. We use NSApplicationSupportDirectory + bundleId as the working directory path as recommended by Apple. Then we create "CameraUploads" folder under the working directory. Since the camera upload directory is used for data caching and processing, we will exclude the folder from iCould backup.

 @return The URL for camera upload directory
 */
- (NSURL *)cameraUploadURL;


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
