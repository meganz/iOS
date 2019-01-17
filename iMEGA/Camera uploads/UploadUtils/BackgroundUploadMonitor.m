
#import "BackgroundUploadMonitor.h"
#import "CameraUploadManager+Settings.h"
@import CoreLocation;

@interface BackgroundUploadMonitor () <CLLocationManagerDelegate>

@property (strong, nonatomic) CLLocationManager *locationManager;

@end

@implementation BackgroundUploadMonitor

- (CLLocationManager *)locationManager {
    if (_locationManager == nil) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.allowsBackgroundLocationUpdates = YES;
    }
    
    return _locationManager;
}

- (void)startBackgroundUploadIfPossible {
    if (CameraUploadManager.isBackgroundUploadAllowed && CLLocationManager.authorizationStatus == kCLAuthorizationStatusAuthorizedAlways) {
        [self.locationManager startMonitoringVisits];
    }
}

- (void)stopBackgroundUpload {
    [self.locationManager stopMonitoringVisits];
}

#pragma mark - Location manager delegate

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    switch (status) {
        case kCLAuthorizationStatusAuthorizedAlways:
            [self startBackgroundUploadIfPossible];
            break;
        default:
            CameraUploadManager.backgroundUploadAllowed = NO;
            break;
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    if (error.code == kCLErrorDenied) {
        [self stopBackgroundUpload];
    }
}

@end
