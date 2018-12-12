
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (ImageIO)

/**
 Strip off GPS metadata from image EXIF if the image contains GPS metadata

 @return a NSData object by stripping off GPS metadata. If the current data doesn't contain GPS metadata, it will be returned.
 */
- (NSData *)mnz_dataByStrippingOffGPSIfNeeded;


/**
 add or overwrite image EXIF according to the given property list.
 
 We will try to match the property index with the image index inside the image data source container. The first property will be used if we can not match the image index.

 @param properties a EXIF property list
 @return a NSData object by adding or overwritting the image EXIF according to the given property list
 */
- (NSData *)mnz_dataByAddingImageProperties:(NSArray <NSDictionary *> *)properties;


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
