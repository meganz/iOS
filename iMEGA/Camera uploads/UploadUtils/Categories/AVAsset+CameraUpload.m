#import "AVAsset+CameraUpload.h"

static NSString * const HEVCCodec = @"hvc1";

@implementation AVAsset (CameraUpload)

- (CGSize)mnz_dimensions {
    AVAssetTrack *videoTrack = [[self tracksWithMediaType:AVMediaTypeVideo] firstObject];
    CGSize size = CGSizeApplyAffineTransform(videoTrack.naturalSize, videoTrack.preferredTransform);
    return CGSizeMake(fabs(size.width), fabs(size.height));
}

- (BOOL)mnz_containsHEVCCodec {
    NSArray<AVAssetTrack *> *tracks = [self tracksWithMediaType:AVMediaTypeVideo];
    for (AVAssetTrack *track in tracks) {
        for (int i = 0; i < track.formatDescriptions.count; i++) {
            CMFormatDescriptionRef desc = (__bridge CMFormatDescriptionRef)track.formatDescriptions[i];
            NSString *codec = FourCCString(CMFormatDescriptionGetMediaSubType(desc));
            if ([[codec lowercaseString] isEqualToString:HEVCCodec]) {
                return YES;
            }
        }
    }
    
    return NO;
}

static NSString * FourCCString(FourCharCode code) {
    char fourChar[5] = {(code >> 24) & 0xFF, (code >> 16) & 0xFF, (code >> 8) & 0xFF, code & 0xFF, 0};
    NSString *result = [NSString stringWithFormat:@"%s", fourChar];
    return [result stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
}

@end
