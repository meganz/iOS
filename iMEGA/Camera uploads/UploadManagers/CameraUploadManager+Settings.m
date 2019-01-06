
#import "CameraUploadManager+Settings.h"

static NSString * const IsCameraUploadsEnabled = @"IsCameraUploadsEnabled";
static NSString * const IsVideoUploadsEnabled = @"IsUploadVideosEnabled";
static NSString * const IsCellularAllowed = @"IsUseCellularConnectionEnabled";
static NSString * const ShouldConvertHEIFPhoto = @"ShouldConvertHEIFPhoto";
static NSString * const ShouldConvertHEVCVideo = @"ShouldConvertHEVCVideo";

@implementation CameraUploadManager (Settings)

+ (void)clearLocalSettings {
    [NSUserDefaults.standardUserDefaults removeObjectForKey:IsCameraUploadsEnabled];
    [NSUserDefaults.standardUserDefaults removeObjectForKey:IsVideoUploadsEnabled];
    [NSUserDefaults.standardUserDefaults removeObjectForKey:IsCellularAllowed];
    [NSUserDefaults.standardUserDefaults removeObjectForKey:ShouldConvertHEIFPhoto];
    [NSUserDefaults.standardUserDefaults removeObjectForKey:ShouldConvertHEVCVideo];
}

+ (BOOL)isCameraUploadEnabled {
    return [NSUserDefaults.standardUserDefaults boolForKey:IsCameraUploadsEnabled];
}

+ (void)setCameraUploadEnabled:(BOOL)cameraUploadEnabled {
    [NSUserDefaults.standardUserDefaults setBool:cameraUploadEnabled forKey:IsCameraUploadsEnabled];
    [self setConvertHEIFPhoto:YES];
}

+ (BOOL)isVideoUploadEnabled {
    return [NSUserDefaults.standardUserDefaults boolForKey:IsVideoUploadsEnabled];
}

+ (void)setVideoUploadEnabled:(BOOL)videoUploadEnabled {
    return [NSUserDefaults.standardUserDefaults setBool:videoUploadEnabled forKey:IsVideoUploadsEnabled];
}

+ (BOOL)isCellularUploadAllowed {
    return [NSUserDefaults.standardUserDefaults boolForKey:IsCellularAllowed];
}

+ (void)setCellularUploadAllowed:(BOOL)cellularUploadAllowed {
    [NSUserDefaults.standardUserDefaults setBool:cellularUploadAllowed forKey:IsCellularAllowed];
}

+ (BOOL)shouldConvertHEVCVideo {
    return [NSUserDefaults.standardUserDefaults boolForKey:ShouldConvertHEVCVideo];
}

+ (void)setConvertHEVCVideo:(BOOL)convertHEVCVideo {
    [NSUserDefaults.standardUserDefaults setBool:convertHEVCVideo forKey:ShouldConvertHEVCVideo];
}

+ (BOOL)shouldConvertHEIFPhoto {
    return [NSUserDefaults.standardUserDefaults boolForKey:ShouldConvertHEIFPhoto];
}

+ (void)setConvertHEIFPhoto:(BOOL)convertHEIFPhoto {
    [NSUserDefaults.standardUserDefaults setBool:convertHEIFPhoto forKey:ShouldConvertHEIFPhoto];
}

@end
