
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURL (CameraUpload)

/**
 A pre-defined URL for camera upload. We use NSApplicationSupportDirectory + bundleId as the working directory path as recommended by Apple. Then we create "CameraUploads" folder under the working directory. Since the camera upload directory is used for data caching and processing, we will exclude the folder from iCould backup.
 
 @return The URL for camera upload directory
 */
@property (class, nonatomic, readonly) NSURL *mnz_cameraUploadURL;

+ (NSURL *)mnz_assetDirectoryURLForLocalIdentifier:(NSString *)localIdentifier;

+ (NSURL *)mnz_archivedURLForLocalIdentifier:(NSString *)localIdentifier;

@end

NS_ASSUME_NONNULL_END
