
#import "NSData+CameraUpload.h"

@implementation NSData (CameraUpload)

- (BOOL)mnz_exportToURL:(NSURL *)URL shouldStripGPSInfo:(BOOL)shouldStripGPSInfo {
    if (!shouldStripGPSInfo || (shouldStripGPSInfo && ![self mnz_containsGPSInfo])) {
        return [self writeToURL:URL atomically:YES];
    }
    
    return [self mnz_exportToURL:URL imageType:nil shouldStripGPSInfo:shouldStripGPSInfo];
}

- (BOOL)mnz_exportToURL:(NSURL *)URL imageType:(NSString *)imageUTIType shouldStripGPSInfo:(BOOL)shouldStripGPSInfo {
    NSDictionary *removeGPSDict = @{(__bridge NSString *)kCGImagePropertyGPSDictionary : (__bridge NSNull *)kCFNull};
    return [self mnz_exportToURL:URL imageType:imageUTIType imageProperties:shouldStripGPSInfo ? @[removeGPSDict] : @[]];
}

- (BOOL)mnz_exportToURL:(NSURL *)URL imageType:(NSString *)imageUTIType imageProperties:(NSArray <NSDictionary *> *)properties {
    BOOL isExportedSucceeded = NO;

    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)self, NULL);
    if (source) {
        CFStringRef type = (__bridge CFStringRef)imageUTIType;
        if (imageUTIType.length == 0) {
            type = CGImageSourceGetType(source);
        }
        size_t size = CGImageSourceGetCount(source);
        CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)URL, type, size, NULL);
        if (destination) {
            for (size_t index = 0; index < size; index++) {
                NSDictionary *property = nil;
                if (properties.count > 0) {
                    property = properties[0];
                    if (properties.count > index) {
                        property = properties[index];
                    }
                }
                
                CGImageDestinationAddImageFromSource(destination, source, index, (__bridge CFDictionaryRef)property);
            }
            
            isExportedSucceeded = CGImageDestinationFinalize(destination);
            CFRelease(destination);
        }
        
        CFRelease(source);
    }
    
    return isExportedSucceeded;
}

- (BOOL)mnz_containsGPSInfo {
    BOOL hasGPS = NO;
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)self, NULL);
    if (source) {
        size_t size = CGImageSourceGetCount(source);
        for (size_t index = 0; index < size; index++) {
            NSDictionary *sourcePropertyDict = (__bridge_transfer NSDictionary *)CGImageSourceCopyPropertiesAtIndex(source, index, NULL);
            if (sourcePropertyDict[(__bridge NSString *)kCGImagePropertyGPSDictionary] != nil) {
                hasGPS = YES;
                break;
            }
        }
        
        CFRelease(source);
    }
    
    return hasGPS;
}

- (NSArray <NSDictionary *> *)mnz_imagePropertiesByStrippingGPSInfo:(BOOL)shouldStripGPSInfo {
    NSMutableArray *properties = [NSMutableArray array];
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)self, NULL);
    if (source) {
        size_t size = CGImageSourceGetCount(source);
        for (size_t index = 0; index < size; index++) {
            NSDictionary *sourcePropertyDict = (__bridge_transfer NSDictionary *)CGImageSourceCopyPropertiesAtIndex(source, index, NULL);
            if (sourcePropertyDict == NULL) {
                continue;
            }
            
            if (shouldStripGPSInfo) {
                NSMutableDictionary *property = [sourcePropertyDict mutableCopy];
                property[(__bridge NSString *)kCGImagePropertyGPSDictionary] = (__bridge NSNull *)kCFNull;
                [properties addObject:[property copy]];
            } else {
                [properties addObject:sourcePropertyDict];
            }
        }
        CFRelease(source);
    }
    
    return [properties copy];
}

@end
