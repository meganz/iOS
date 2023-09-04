#import "AVURLAsset+CameraUpload.h"
@import CoreServices;

@implementation AVURLAsset (CameraUpload)

- (BOOL)mnz_isQuickTimeMovie {
    NSString *extension = self.URL.pathExtension;
    CFStringRef type = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)extension, NULL);
    BOOL isQuickTimeMovie = UTTypeConformsTo(type, kUTTypeQuickTimeMovie);
    CFRelease(type);
    return isQuickTimeMovie;
}

@end
