
#import "ImageExportor.h"

@implementation ImageExportor

- (BOOL)exportImageData:(NSData *)data toURL:(NSURL *)URL shouldStripGPSInfo:(BOOL)shouldStripGPSInfo {
    return [self exportImageData:data toURL:URL outputImageUTIType:nil shouldStripGPSInfo:shouldStripGPSInfo];
}

- (BOOL)exportImageData:(NSData *)data toURL:(NSURL *)URL outputImageUTIType:(NSString *)UTIType shouldStripGPSInfo:(BOOL)shouldStripGPSInfo {
    BOOL isExportedSuccessfully = NO;
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    if (source) {
        if ([self shouldConvertImageSource:source toUTIType:UTIType] || (shouldStripGPSInfo && [self containsGPSInfoInImageSource:source])) {
            isExportedSuccessfully = [self exportImageSource:source toURL:URL outputImageUTIType:UTIType shouldStripGPSInfo:shouldStripGPSInfo];
        } else {
            isExportedSuccessfully = [data writeToURL:URL atomically:YES];
        }

        CFRelease(source);
    }
    
    return isExportedSuccessfully;
}

- (BOOL)exportImageFile:(NSURL *)inputURL toURL:(NSURL *)outputURL shouldStripGPSInfo:(BOOL)shouldStripGPSInfo {
    return [self exportImageFile:inputURL toURL:outputURL outputImageUTIType:nil shouldStripGPSInfo:shouldStripGPSInfo];
}

- (BOOL)exportImageFile:(NSURL *)inputURL toURL:(NSURL *)outputURL outputImageUTIType:(NSString *)UTIType shouldStripGPSInfo:(BOOL)shouldStripGPSInfo {
    BOOL isExportedSuccessfully = NO;
    CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)inputURL, NULL);
    if (source) {
        if ([self shouldConvertImageSource:source toUTIType:UTIType] || (shouldStripGPSInfo && [self containsGPSInfoInImageSource:source])) {
            isExportedSuccessfully = [self exportImageSource:source toURL:outputURL outputImageUTIType:UTIType shouldStripGPSInfo:shouldStripGPSInfo];
        } else {
            isExportedSuccessfully = [NSFileManager.defaultManager copyItemAtURL:inputURL toURL:outputURL error:nil];
        }
        
        CFRelease(source);
    }
    
    return isExportedSuccessfully;
}

- (BOOL)exportImageSource:(CGImageSourceRef)source toURL:(NSURL *)URL outputImageUTIType:(NSString *)UTIType shouldStripGPSInfo:(BOOL)shouldStripGPSInfo {
    if (source == NULL) {
        return NO;
    }
    
    BOOL isExportedSuccessfully = NO;
    
    size_t size = CGImageSourceGetCount(source);
    CFStringRef newType = (__bridge CFStringRef)UTIType;
    CFStringRef sourceType = CGImageSourceGetType(source);
    BOOL shouldConvertImageType = [self shouldConvertImageSource:source toUTIType:UTIType];
    
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
                isExportedSuccessfully = [self exportImageSource:source toURL:URL alwaysEncodeToImageUTIType:(__bridge NSString *)sourceType imageProperty:removeGPSDict];
            }
        }
    }
    
    return isExportedSuccessfully;
}

- (BOOL)exportImageSource:(CGImageSourceRef)source toURL:(NSURL *)URL alwaysEncodeToImageUTIType:(NSString *)UTIType imageProperty:(NSDictionary *)property {
    if (source == NULL) {
        return NO;
    }
    
    BOOL isExportedSuccessfully = NO;
    size_t size = CGImageSourceGetCount(source);
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)URL, (__bridge CFStringRef)UTIType, size, NULL);
    
    if (destination) {
        for (size_t index = 0; index < size; index++) {
            CGImageDestinationAddImageFromSource(destination, source, index, (__bridge CFDictionaryRef)property);
        }
        isExportedSuccessfully = CGImageDestinationFinalize(destination);
        
        CFRelease(destination);
    }
    
    return isExportedSuccessfully;
}

#pragma mark - check UTI type

- (BOOL)shouldConvertImageSource:(CGImageSourceRef)source toUTIType:(NSString *)UTIType {
    CFStringRef sourceType = CGImageSourceGetType(source);
    CFStringRef newType = (__bridge CFStringRef)UTIType;
    return UTIType.length > 0 && CFStringCompare(sourceType, newType, kCFCompareCaseInsensitive) != kCFCompareEqualTo;
}

#pragma mark - check GPS info

- (BOOL)containsGPSInfoInData:(NSData *)data {
    BOOL hasGPS = NO;
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    if (source) {
        hasGPS = [self containsGPSInfoInImageSource:source];
        CFRelease(source);
    }
    
    return hasGPS;
}

- (BOOL)containsGPSInfoInFile:(NSURL *)URL {
    BOOL hasGPS = NO;
    CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)URL, NULL);
    if (source) {
        hasGPS = [self containsGPSInfoInImageSource:source];
        CFRelease(source);
    }
    
    return hasGPS;
}

- (BOOL)containsGPSInfoInImageSource:(CGImageSourceRef)source {
    BOOL hasGPS = NO;
    
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
    }
    
    return hasGPS;
}

@end
