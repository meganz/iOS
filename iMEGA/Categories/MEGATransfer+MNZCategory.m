
#import "MEGATransfer+MNZCategory.h"

#import "NSString+MNZCategory.h"

@implementation MEGATransfer (MNZCategory)

- (void)mnz_setCoordinatesWithApi:(MEGASdk *)api {
    MEGANode *node = [api nodeForHandle:self.nodeHandle];
    if (self.fileName.mnz_isImagePathExtension && (!node.latitude || !node.longitude)) {
        NSData *data = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:[NSHomeDirectory() stringByAppendingPathComponent:self.path]]];
        CGImageSourceRef imageData = CGImageSourceCreateWithData((CFDataRef)data, NULL);
        if (imageData) {
            NSDictionary *metadata = (__bridge NSDictionary *)CGImageSourceCopyPropertiesAtIndex(imageData, 0, NULL);
            NSDictionary *exifDictionary = [metadata objectForKey:(NSString *)kCGImagePropertyGPSDictionary];
            
            if(exifDictionary) {
                NSNumber *latitude = [exifDictionary objectForKey:@"Latitude"];
                NSNumber *longitude = [exifDictionary objectForKey:@"Longitude"];
                if (latitude && longitude) {
                    [api setNodeCoordinates:node latitude:latitude longitude:longitude];
                }
            }
            
            CFRelease(imageData);
        }
    }
}

@end
