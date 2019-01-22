
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (CameraUpload)

/**
 Export the image to an URL and with the option to strip off GPS info from image EXIF

 @param URL where you want to export your image data
 @param shouldStripGPSInfo whether to strip off GPS info from EXIF
 @return YES if the export succeeded, otherwise NO
 */
- (BOOL)mnz_exportToURL:(NSURL *)URL shouldStripGPSInfo:(BOOL)shouldStripGPSInfo;


/**
 Export the image to an URL and with the options to convert to another image type and strip off GPS info from image EXIF

 @param URL where you want to export your image data
 @param imageUTIType new image data UTI type. If it is null, image type won't be converted and the source image type will be used.
 @param shouldStripGPSInfo whether to strip off GPS info from EXIF
 @return YES if the export succeeded, otherwise NO
 */
- (BOOL)mnz_exportToURL:(NSURL *)URL imageType:(nullable NSString *)imageUTIType shouldStripGPSInfo:(BOOL)shouldStripGPSInfo;


/**
 check whether a image EXIF contains GPS metadata.
 A image data could contains multiple images, we return YES if anyone of them contains GPS metadata.

 @return YES if the image data contains GPS metadata
 */
- (BOOL)mnz_containsGPSInfo;

@end

NS_ASSUME_NONNULL_END
