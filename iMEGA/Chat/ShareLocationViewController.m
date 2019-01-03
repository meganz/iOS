
#import "ShareLocationViewController.h"

#import <MapKit/MapKit.h>

#import "Helper.h"
#import "MEGASdkManager.h"

#import "LocationSearchTableViewController.h"

@interface ShareLocationViewController () <MKMapViewDelegate, CLLocationManagerDelegate, LocationSearchTableViewControllerDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIView *mapOptionsView;
@property (weak, nonatomic) IBOutlet UIView *sendLocationView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *sendLocationLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;

@property (strong, nonatomic) UISearchController *searchController;

@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) id<MKAnnotation> annotation;
@property (nonatomic, getter=isCurrentLocation) BOOL currentLocation;

@property (nonatomic, strong) NSArray <MKMapItem *> *mapItems;

@end

@implementation ShareLocationViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    if (CLLocationManager.locationServicesEnabled) {
        if (_locationManager == nil) {
            _locationManager = [[CLLocationManager alloc] init];
        }
        
        [self.locationManager requestWhenInUseAuthorization];
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        [self.locationManager startUpdatingLocation];
        _currentLocation = YES;
    }
    
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sendGeolocation:)];
    gesture.numberOfTapsRequired = 1;
    [self.sendLocationView addGestureRecognizer:gesture];
    
    self.sendLocationLabel.text = AMLocalizedString(@"Send This Location", @"Title of the button to share a location in a chat.");
    
    UIView *layer = [[UIView alloc] initWithFrame:CGRectMake(0, 45, self.mapOptionsView.frame.size.width, 1)];
    layer.backgroundColor = [UIColor colorWithRed:0.85 green:0.85 blue:0.87 alpha:1];
    [self.mapOptionsView addSubview:layer];
    
    LocationSearchTableViewController *locationSearchTVC = [[UIStoryboard storyboardWithName:@"Chat" bundle:nil] instantiateViewControllerWithIdentifier:@"LocationSearchTableViewControllerID"];
    locationSearchTVC.mapView = self.mapView;
    locationSearchTVC.delegate = self;

    UINavigationController *navigationViewController = [[UINavigationController alloc] initWithRootViewController:locationSearchTVC];
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:navigationViewController];
    self.searchController.searchResultsUpdater = locationSearchTVC;
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    self.searchController.dimsBackgroundDuringPresentation = YES;
    self.searchController.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchController.searchBar.translucent = NO;
    self.searchController.searchBar.backgroundImage = [UIImage imageWithCGImage:(__bridge CGImageRef)(UIColor.clearColor)];
    self.searchController.searchBar.barTintColor = UIColor.whiteColor;
    self.searchController.searchBar.tintColor = UIColor.mnz_redMain;
    self.searchController.searchBar.frame = CGRectMake(0, 0, self.view.frame.size.width, self.searchController.searchBar.frame.size.height);
    self.searchController.searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:self.searchController.searchBar];
    
    self.navigationItem.title = AMLocalizedString(@"Send Location", @"Alert title shown when the user opens a shared Geolocation for the first time from any client, we will show a confirmation dialog warning the user that he is now leaving the E2EE paradigm");
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.locationManager stopUpdatingLocation];
}

#pragma mark - Private

- (void)sendGeolocationWithCoordinage2d:(CLLocationCoordinate2D)coordinate {
    MKMapSnapshotOptions *mapSnapshotOptions = [[MKMapSnapshotOptions alloc] init];
    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(coordinate, 1000, 1000);
    mapSnapshotOptions.region = region;
    mapSnapshotOptions.scale = UIScreen.mainScreen.scale;
    mapSnapshotOptions.size = CGSizeMake(750 / UIScreen.mainScreen.scale, 750 / UIScreen.mainScreen.scale);
    mapSnapshotOptions.showsBuildings = YES;
    mapSnapshotOptions.showsPointsOfInterest = YES;
    
    MKMapSnapshotter *snapShotter = [[MKMapSnapshotter alloc] initWithOptions:mapSnapshotOptions];
    [snapShotter startWithCompletionHandler:^(MKMapSnapshot * _Nullable snapshot, NSError * _Nullable error) {
        if (error || !snapshot) {
            MEGALogError(@"[Share Location] Error creating the map snapshot %@", error);
            return;
        }
        
        UIImage *image = snapshot.image;
        
        MKAnnotationView *pin = [[MKPinAnnotationView alloc] initWithAnnotation:nil reuseIdentifier:nil];
        CGPoint coordinatePoint = [snapshot pointForCoordinate:coordinate];
        
        coordinatePoint.x += pin.centerOffset.x - (CGRectGetWidth(pin.bounds) / 2.0);
        coordinatePoint.y += pin.centerOffset.y - (CGRectGetHeight(pin.bounds) / 2.0);
        
        UIGraphicsBeginImageContextWithOptions(image.size, YES, image.scale);
        {
            [image drawAtPoint:CGPointZero];
            [pin.image drawAtPoint:coordinatePoint];
            image = UIGraphicsGetImageFromCurrentImageContext();
        }
        UIGraphicsEndImageContext();
        
        NSData *imageData = UIImageJPEGRepresentation(image, 0.3);
        NSString *imageB64 = [imageData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
        
        MEGAChatMessage *message;
        
        if (self.editMessage) {
            uint64_t messageId = (self.editMessage.status == MEGAChatMessageStatusSending) ? self.editMessage.temporalId : self.editMessage.messageId;
            message = [[MEGASdkManager sharedMEGAChatSdk] editGeolocationForChat:self.chatRoom.chatId messageId:messageId longitude:coordinate.longitude latitude:coordinate.latitude image:imageB64];
        } else {
            message = [[MEGASdkManager sharedMEGAChatSdk] sendGeolocationToChat:self.chatRoom.chatId longitude:coordinate.longitude latitude:coordinate.latitude image:imageB64];
        }
        MEGALogDebug(@"[Share Location] Send message %@", message);
        if (message) {
            [self.shareLocationViewControllerDelegate locationMessage:message editing:self.editMessage];            
            [self dismissViewControllerAnimated:YES completion:nil];
        } else {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"error", nil) message:@"Share location is not possible" preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"ok", nil) style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alertController animated:YES completion:nil];
        }
    }];
}

- (void)sendGeolocation:(UITapGestureRecognizer *)gesture {
    [self sendGeolocationWithCoordinage2d:self.mapView.centerCoordinate];
}

#pragma mark - IBAction

- (IBAction)infoButtonTouchUpInside:(UIButton *)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:AMLocalizedString(@"Map settings", @"Title of the alert that allows change between different maps: Standar, Satellite or Hybrid.") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    if (self.mapView.mapType != MKMapTypeStandard) {
        [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"Standard", @"Standard") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            self.mapView.mapType = MKMapTypeStandard;
        }]];
    }
    if (self.mapView.mapType != MKMapTypeSatellite) {
        [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"Satellite", @"Satellite") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            self.mapView.mapType = MKMapTypeSatellite;
        }]];
    }
    if (self.mapView.mapType != MKMapTypeHybrid) {
        [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"Hybrid", @"Hybrid") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            self.mapView.mapType = MKMapTypeHybrid;
        }]];
    }
    
    [alertController addAction:[UIAlertAction actionWithTitle:AMLocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (IBAction)currentLocationTouchUpInside:(UIButton *)sender {    
    MKCoordinateRegion mapRegion;
    mapRegion.center = self.mapView.userLocation.coordinate;
    mapRegion.span.latitudeDelta = 0.01;
    mapRegion.span.longitudeDelta = 0.01;
    
    [self.mapView setRegion:mapRegion animated: YES];
}

#pragma mark - CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    MEGALogDebug(@"[Share Location] Did update locations %@", locations);
    if (self.isCurrentLocation) {
        self.currentLocation = NO;
        
        CLLocation *location = locations.lastObject;
        CLLocationCoordinate2D center = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude);
        MKCoordinateRegion region = MKCoordinateRegionMake(center, MKCoordinateSpanMake(0.01, 0.01));
        
        [self.mapView setRegion:region animated:YES];
        
        if (self.mapView.annotations.count != 0) {
            self.annotation = self.mapView.annotations[0];
        }
        
        MKPointAnnotation *pointAnnotation = [[MKPointAnnotation alloc] init];
        pointAnnotation.coordinate = location.coordinate;
        [self.mapView addAnnotation:pointAnnotation];
    }
}

#pragma mark - MKMapViewDelegate

- (void)mapViewDidChangeVisibleRegion:(MKMapView *)mapView {
    [mapView removeAnnotations:mapView.annotations];
    
    MKPointAnnotation *pointAnnotation = [[MKPointAnnotation alloc] init];
    pointAnnotation.coordinate = mapView.region.center;
    [mapView addAnnotation:pointAnnotation];
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:mapView.centerCoordinate.latitude longitude:mapView.centerCoordinate.longitude];

    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        if (!error && placemarks.count > 0) {
            CLPlacemark *placemark = placemarks.firstObject;
            self.subtitleLabel.text = placemark.name;
        } else {
            self.subtitleLabel.text = [NSString stringWithFormat:AMLocalizedString(@"Accurate to %d meters", @"Label to give feedback to the user when he is going to share his location, indicating that it may not be the exact location."), (int)location.horizontalAccuracy];
        }
    }];
}

#pragma mark - LocationSearchTableViewControllerDelegate

- (void)didSelectPlacemark:(MKPlacemark *)placemark {
    [self sendGeolocationWithCoordinage2d:placemark.coordinate];
}

@end
