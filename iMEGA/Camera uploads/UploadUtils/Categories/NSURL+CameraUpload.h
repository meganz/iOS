
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class MEGANode;

@interface NSURL (CameraUpload)

/**
 A pre-defined URL for camera upload. We use NSApplicationSupportDirectory + bundleId as the working directory path as recommended by Apple. Then we create "CameraUploads" folder under the working directory. Since the camera upload directory is used for data caching and processing, we will exclude the folder from iCloud backup.
 
 @return The URL for camera upload directory
 */
@property (class, nonatomic, readonly, nullable) NSURL *mnz_cameraUploadURL;

+ (NSURL *)mnz_assetURLForLocalIdentifier:(NSString *)localIdentifier;
+ (NSURL *)mnz_archivedUploadInfoURLForLocalIdentifier:(NSString *)localIdentifier;

- (BOOL)mnz_exportVideoThumbnailToImageURL:(NSURL *)imageURL;

- (BOOL)mnz_cacheThumbnailForNode:(MEGANode *)node;
- (BOOL)mnz_cachePreviewForNode:(MEGANode *)node;

@end

NS_ASSUME_NONNULL_END
