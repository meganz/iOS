
#import "NSData+ImageIO.h"

@implementation NSData (ImageIO)

- (NSData *)mnz_dataByStrippingOffGPSIfNeeded {
    if (![self mnz_containsGPSInfo]) {
        return self;
    }
    
    NSDictionary *removeGPSDict = @{(__bridge NSString *)kCGImagePropertyGPSDictionary : (__bridge NSNull *)kCFNull};
    return [self mnz_dataByAddingImageProperties:@[removeGPSDict]];
}

- (NSData *)mnz_dataByAddingImageProperties:(NSArray <NSDictionary *> *)properties {
    if (properties.count == 0) {
        return self;
    }
    
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)self, NULL);
    if (source) {
        NSMutableData *mutableData = [NSMutableData data];
        
        size_t size = CGImageSourceGetCount(source);
        CFStringRef type = CGImageSourceGetType(source);
        CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)mutableData, type, size, NULL);
        
        if (destination) {
            for (size_t index = 0; index < size; index++) {
                NSDictionary *property = properties[0];
                if (properties.count > index) {
                    property = properties[index];
                }
                
                CGImageDestinationAddImageFromSource(destination, source, index, (__bridge CFDictionaryRef)property);
            }
            
            if (!CGImageDestinationFinalize(destination)) {
                MEGALogDebug(@"[Camera Upload] image data without GPS created failed");
            }
            
            CFRelease(destination);
        }
        
        CFRelease(source);
        
        return [mutableData copy];
    } else {
        return nil;
    }
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
