
#import "MOAssetUploadRecord+CoreDataClass.h"
@import Photos;

@implementation MOAssetUploadRecord

- (NSString *)description {
    return [NSString stringWithFormat:@"%@, %@, %@", self.localIdentifier, self.status, [self stringFromMediaType:self.mediaType.integerValue]];
}

- (NSString *)stringFromMediaType:(PHAssetMediaType)mediaType {
    switch (mediaType) {
        case PHAssetMediaTypeUnknown:
            return @"Unknown";
            break;
        case PHAssetMediaTypeImage:
            return @"Image";
            break;
        case PHAssetMediaTypeVideo:
            return @"Video";
            break;
        case PHAssetMediaTypeAudio:
            return @"Audio";
            break;
        default:
            return @"Undefined";
            break;
    }
}

@end
