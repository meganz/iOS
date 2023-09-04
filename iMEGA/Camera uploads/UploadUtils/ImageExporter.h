#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ImageExporter : NSObject

/**
 Export the image to an URL and with the options to convert to another image type and strip off GPS info from image EXIF
 
 @param source the image source to export
 @param URL where you want to export your image data
 @param UTIType new image data UTI type. If it is null, image type won't be converted and the source image type will be used.
 @param shouldStripGPSInfo whether to strip off GPS info from EXIF
 @return YES if the export succeeded, otherwise NO
 */
- (BOOL)exportImageSource:(CGImageSourceRef)source toURL:(NSURL *)URL outputImageUTIType:(nullable NSString *)UTIType shouldStripGPSInfo:(BOOL)shouldStripGPSInfo;

- (BOOL)exportImageData:(NSData *)data toURL:(NSURL *)URL shouldStripGPSInfo:(BOOL)shouldStripGPSInfo;
- (BOOL)exportImageData:(NSData *)data toURL:(NSURL *)URL outputImageUTIType:(nullable NSString *)UTIType shouldStripGPSInfo:(BOOL)shouldStripGPSInfo;

- (BOOL)exportImageFile:(NSURL *)inputURL toURL:(NSURL *)outputURL shouldStripGPSInfo:(BOOL)shouldStripGPSInfo;
- (BOOL)exportImageFile:(NSURL *)inputURL toURL:(NSURL *)outputURL outputImageUTIType:(nullable NSString *)UTIType shouldStripGPSInfo:(BOOL)shouldStripGPSInfo;

/**
 check whether a image EXIF contains GPS metadata.
 A image data could contains multiple images, we return YES if anyone of them contains GPS metadata.

 @param source the image source to check against
 @return YES if the image source contains GPS metadata
 */
- (BOOL)containsGPSInfoInImageSource:(CGImageSourceRef)source;

- (BOOL)containsGPSInfoInData:(NSData *)data;

- (BOOL)containsGPSInfoInFile:(NSURL *)URL;

@end

NS_ASSUME_NONNULL_END
