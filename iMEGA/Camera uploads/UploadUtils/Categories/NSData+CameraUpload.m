
#import "NSData+CameraUpload.h"

@implementation NSData (CameraUpload)

- (BOOL)mnz_exportToURL:(NSURL *)URL shouldStripGPSInfo:(BOOL)shouldStripGPSInfo {
    return [self mnz_exportToURL:URL imageType:nil shouldStripGPSInfo:shouldStripGPSInfo];
}

- (BOOL)mnz_exportToURL:(NSURL *)URL imageType:(NSString *)imageUTIType shouldStripGPSInfo:(BOOL)shouldStripGPSInfo {
    BOOL isExportedSuccessfully = NO;
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)self, NULL);
    if (source) {
        size_t size = CGImageSourceGetCount(source);
        CFStringRef sourceType = CGImageSourceGetType(source);
        CFStringRef newType = (__bridge CFStringRef)imageUTIType;
        BOOL shouldConvertImageType = !(imageUTIType.length == 0 || CFStringCompare(sourceType, newType, kCFCompareCaseInsensitive) == kCFCompareEqualTo);
        
        if (!shouldConvertImageType && (!shouldStripGPSInfo || (shouldStripGPSInfo && ![self mnz_containsGPSInfo]))) {
            return [self writeToURL:URL atomically:YES];
        }
        
        CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)URL, shouldConvertImageType ? newType : sourceType, size, NULL);
        
        if (destination) {
            NSDictionary *removeGPSDict = @{(__bridge NSString *)kCGImageMetadataShouldExcludeGPS : @(shouldStripGPSInfo)};
            for (size_t index = 0; index < size; index++) {
                CGImageDestinationAddImageFromSource(destination, source, index, (__bridge CFDictionaryRef)removeGPSDict);
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
