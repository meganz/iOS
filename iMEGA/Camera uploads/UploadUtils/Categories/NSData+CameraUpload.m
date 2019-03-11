
#import "NSData+CameraUpload.h"

@implementation NSData (CameraUpload)

- (BOOL)mnz_exportToURL:(NSURL *)URL shouldStripGPSInfo:(BOOL)shouldStripGPSInfo {
    return [self mnz_exportToURL:URL outputImageUTIType:nil shouldStripGPSInfo:shouldStripGPSInfo];
}

- (BOOL)mnz_exportToURL:(NSURL *)URL outputImageUTIType:(NSString *)UTIType shouldStripGPSInfo:(BOOL)shouldStripGPSInfo {
    BOOL isExportedSuccessfully = NO;
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)self, NULL);
    if (source) {
        size_t size = CGImageSourceGetCount(source);
        CFStringRef sourceType = CGImageSourceGetType(source);
        CFStringRef newType = (__bridge CFStringRef)UTIType;
        BOOL shouldConvertImageType = !(UTIType.length == 0 || CFStringCompare(sourceType, newType, kCFCompareCaseInsensitive) == kCFCompareEqualTo);
        
        if (!shouldConvertImageType && (!shouldStripGPSInfo || (shouldStripGPSInfo && ![self mnz_containsGPSInfo]))) {
            CFRelease(source);
            return [self writeToURL:URL atomically:YES];
        }
        
        CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)URL, shouldConvertImageType ? newType : sourceType, size, NULL);
        
        if (destination) {
            NSDictionary *removeGPSDict = @{(__bridge NSString *)kCGImageMetadataShouldExcludeGPS : @(shouldStripGPSInfo)};
            
            if (shouldConvertImageType) {
                for (size_t index = 0; index < size; index++) {
                    CGImageDestinationAddImageFromSource(destination, source, index, (__bridge CFDictionaryRef)removeGPSDict);
                }
                isExportedSuccessfully = CGImageDestinationFinalize(destination);
                CFRelease(destination);
            } else {
                NSMutableDictionary *metadata = [removeGPSDict mutableCopy];
                CGImageMetadataRef sourceMetadata = CGImageSourceCopyMetadataAtIndex(source, 0, NULL);
                [metadata addEntriesFromDictionary:@{(__bridge NSString *)kCGImageDestinationMetadata : (__bridge id)sourceMetadata,
                                                     (__bridge NSString *)kCGImageDestinationMergeMetadata : @(YES)}];
                if (sourceMetadata) {
                    CFRelease(sourceMetadata);
                }
                
                isExportedSuccessfully = CGImageDestinationCopyImageSource(destination, source, (__bridge CFDictionaryRef)[metadata copy], NULL);
                CFRelease(destination);
                
                if (!isExportedSuccessfully) {
                    isExportedSuccessfully = [self mnz_exportToURL:URL alwaysEncodeToImageUTIType:sourceType imageProperty:removeGPSDict];
                }
            }
        }
        
        CFRelease(source);
    }
    
    return isExportedSuccessfully;
}

- (BOOL)mnz_exportToURL:(NSURL *)URL alwaysEncodeToImageUTIType:(CFStringRef)imageUTI imageProperty:(NSDictionary *)property {
    BOOL isExportedSuccessfully = NO;
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)self, NULL);
    if (source) {
        size_t size = CGImageSourceGetCount(source);
        CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)URL, imageUTI, size, NULL);
        
        if (destination) {
            for (size_t index = 0; index < size; index++) {
                CGImageDestinationAddImageFromSource(destination, source, index, (__bridge CFDictionaryRef)property);
            }
            isExportedSuccessfully = CGImageDestinationFinalize(destination);
            
            CFRelease(destination);
        }
        
        CFRelease(source);
    }
    
    return isExportedSuccessfully;
}

- (BOOL)mnz_containsGPSInfo {
    BOOL hasGPS = NO;
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)self, NULL);
    if (source) {
        size_t size = CGImageSourceGetCount(source);
        for (size_t index = 0; index < size; index++) {
            NSDictionary *sourcePropertyDict = (__bridge_transfer NSDictionary *)CGImageSourceCopyPropertiesAtIndex(source, index, NULL);
            id GPSValue = sourcePropertyDict[(__bridge NSString *)kCGImagePropertyGPSDictionary];
            if (!(GPSValue == nil || [GPSValue isEqual:[NSNull null]])) {
                hasGPS = YES;
                break;
            }
        }
        
        CFRelease(source);
    }
    
    return hasGPS;
}

@end
