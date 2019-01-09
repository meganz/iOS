
#import "BackgroundUploadManager.h"
#import "CameraUploadManager+Settings.h"
@import CoreLocation;

@interface BackgroundUploadManager () <CLLocationManagerDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;

@end

@implementation BackgroundUploadManager

+ (instancetype)shared {
    static id sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

- (CLLocationManager *)locationManager {
    if (_locationManager == nil) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
    }
    
    return _locationManager;
}

- (void)enableBackgroundUploadIfPossible {
    if ([CameraUploadManager isBackgroundUploadEnabled] &&
        CLLocationManager.authorizationStatus == kCLAuthorizationStatusAuthorizedAlways &&
        CLLocationManager.significantLocationChangeMonitoringAvailable) {
        [self.locationManager startMonitoringSignificantLocationChanges];
    }
}

- (void)disableBackgroundUpload {
    [CameraUploadManager setBackgroundUploadEnabled:NO];
    [self.locationManager stopMonitoringSignificantLocationChanges];
}

#pragma mark - Location manager delegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    switch (status) {
        case kCLAuthorizationStatusAuthorizedAlways:
            [self enableBackgroundUploadIfPossible];
            break;
        default:
            [self disableBackgroundUpload];
            break;
    }
}

@end
