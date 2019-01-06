
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (ImageIO)

/**
 Strip off GPS metadata from image EXIF if the image contains GPS metadata

 @return a new NSData object by stripping off GPS metadata. If the current data doesn't contain GPS metadata, it will be returned.
 */
- (NSData *)mnz_dataByStrippingOffGPSIfNeeded;


/**
 Convert the data to a new image UTI type, and provide the ability to strip off GPS info from EXIF

 @param imageUTIType new image data UTI type. If it is null, image type won't be converted.
 @param shouldStripGPSInfo whether to strip off GPS info from EXIF
 @return a new NSData object by converting to the given type, and the GPS info will be stripped off if `shouldStripGPSInfo` is YES.
 */
- (NSData *)mnz_dataByConvertingToType:(nullable NSString *)imageUTIType shouldStripGPSInfo:(BOOL)shouldStripGPSInfo;


/**
 check whether a image EXIF contains GPS metadata.
 A image data could contains multiple images, we return YES if anyone of them contains GPS metadata.

 @return YES if the image data contains GPS metadata
 */
- (BOOL)mnz_containsGPSInfo;


/**
 Get image EXIF property list with the option to strip off GPS metadata.
 A image data could contains multiple images, that's why here we need to return an array of EXIF property.

 @param shouldStripGPSInfo should strip GPS metadata or not
 @return an array of EXIF property for the image
 */
- (NSArray <NSDictionary *> *)mnz_imagePropertiesByStrippingGPSInfo:(BOOL)shouldStripGPSInfo;

@end

NS_ASSUME_NONNULL_END
