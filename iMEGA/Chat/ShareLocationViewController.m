#import "ShareLocationViewController.h"

#import <MapKit/MapKit.h>

#import "SVProgressHUD.h"

#import "Helper.h"
#import "MEGA-Swift.h"

#import "LocationSearchTableViewController.h"

@import MEGAL10nObjc;

@interface ShareLocationViewController () <MKMapViewDelegate, CLLocationManagerDelegate, LocationSearchTableViewControllerDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UIView *mapOptionsView;
@property (weak, nonatomic) IBOutlet UIView *sendLocationView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *sendLocationLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;

@property (strong, nonatomic) UISearchController *searchController;

@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) MKPointAnnotation *pointAnnotation;

@property (nonatomic, strong) NSArray <MKMapItem *> *mapItems;

@end

@implementation ShareLocationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CLLocationManager *locationManager = CLLocationManager.alloc.init;
    if (!CLLocationManager.locationServicesEnabled || locationManager.authorizationStatus == kCLAuthorizationStatusDenied || locationManager.authorizationStatus == kCLAuthorizationStatusRestricted) {
        NSString *message = [[LocalizedString(@"NSLocationWhenInUseUsageDescription", @"Location Usage Description. In order to protect user's privacy, Apple requires a specific string explaining why location will be accessed.") stringByAppendingString:@"\n\n"] stringByAppendingString:LocalizedString(@"Please go to the Privacy section in your device’s Setting. Enable Location Services and set MEGA to While Using the App or Always.", @"Hint shown to the users, when they want to use the Location Services but they are disabled or restricted for MEGA")];
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"Please allow access", @"Title of a dialog in which we request access to a specific permission, like the Location Services") message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *notNow = [UIAlertAction actionWithTitle:LocalizedString(@"notNow", @"Used in the \"rich previews\", when the user first tries to send an url - we ask them before we generate previews for that URL, since we need to send them unencrypted to our servers.") style:UIAlertActionStyleCancel handler:nil];
        [alertController addAction:notNow];
        UIAlertAction *settings = [UIAlertAction actionWithTitle:LocalizedString(@"settingsTitle", @"Title of the Settings section") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [UIApplication.sharedApplication openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
        }];
        [alertController addAction:settings];
        [self presentViewController:alertController animated:YES completion:nil];
    } else {
        if (_locationManager == nil) {
            _locationManager = [[CLLocationManager alloc] init];
        }
        
        [self.locationManager requestWhenInUseAuthorization];
        self.locationManager.delegate = self;
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        [self.locationManager startUpdatingLocation];
    }
    
    if (self.editMessage) {
        MEGAChatGeolocation *geoLocation = self.editMessage.containsMeta.geolocation;
        CLLocationCoordinate2D center = CLLocationCoordinate2DMake(geoLocation.latitude, geoLocation.longitude);
        MKCoordinateRegion region = MKCoordinateRegionMake(center, MKCoordinateSpanMake(0.01, 0.01));
        [self.mapView setRegion:region animated:YES];
    }
    
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sendGeolocation:)];
    gesture.numberOfTapsRequired = 1;
    [self.sendLocationView addGestureRecognizer:gesture];
    
    self.sendLocationLabel.text = LocalizedString(@"Send This Location", @"Title of the button to share a location in a chat.");
    
    UIView *separatorBetweenButtonsLayer = [UIView.alloc initWithFrame:CGRectMake(0, self.mapOptionsView.frame.size.height / 2, self.mapOptionsView.frame.size.width, 0.5)];
    separatorBetweenButtonsLayer.backgroundColor = [UIColor borderStrong];
    [self.mapOptionsView addSubview:separatorBetweenButtonsLayer];
    
    LocationSearchTableViewController *locationSearchTVC = [[UIStoryboard storyboardWithName:@"Chat" bundle:nil] instantiateViewControllerWithIdentifier:@"LocationSearchTableViewControllerID"];
    locationSearchTVC.mapView = self.mapView;
    locationSearchTVC.delegate = self;

    UINavigationController *navigationViewController = [[UINavigationController alloc] initWithRootViewController:locationSearchTVC];
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:navigationViewController];
    self.searchController.searchResultsUpdater = locationSearchTVC;
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    self.searchController.obscuresBackgroundDuringPresentation = YES;
    self.searchController.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchController.searchBar.translucent = NO;
    self.navigationItem.searchController = self.searchController;
    
    self.navigationItem.title = LocalizedString(@"Send Location", @"Alert title shown when the user opens a shared Geolocation for the first time from any client, we will show a confirmation dialog warning the user that he is now leaving the E2EE paradigm");
    [self updateAppearance];
    
    [AppearanceManager forceSearchBarUpdate:self.searchController.searchBar 
       backgroundColorWhenDesignTokenEnable:[UIColor surface1Background]
                            traitCollection:self.traitCollection];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.locationManager stopUpdatingLocation];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [AppearanceManager forceSearchBarUpdate:self.searchController.searchBar 
           backgroundColorWhenDesignTokenEnable:[UIColor surface1Background]
                                traitCollection:self.traitCollection];
        [self updateAppearance];
    }
}

#pragma mark - Private

- (void)updateAppearance {
    self.mapOptionsView.backgroundColor = self.sendLocationView.backgroundColor = UIColor.systemBackgroundColor;
    
    self.subtitleLabel.textColor = [UIColor mnz_secondaryTextColor];
}

- (void)sendGeolocationWithCoordinate2d:(CLLocationCoordinate2D)coordinate {
    [SVProgressHUD show];
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];

    MKMapSnapshotOptions *mapSnapshotOptions = [[MKMapSnapshotOptions alloc] init];
    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(coordinate, 1000, 1000);
    mapSnapshotOptions.region = region;
    mapSnapshotOptions.scale = UIScreen.mainScreen.scale;
    mapSnapshotOptions.size = CGSizeMake(750 / UIScreen.mainScreen.scale, 750 / UIScreen.mainScreen.scale);
    mapSnapshotOptions.showsBuildings = YES;
    mapSnapshotOptions.pointOfInterestFilter = [MKPointOfInterestFilter filterIncludingAllCategories];
    
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
            message = [MEGAChatSdk.shared editGeolocationForChat:self.chatRoom.chatId messageId:messageId longitude:coordinate.longitude latitude:coordinate.latitude image:imageB64];
        } else {
            message = [MEGAChatSdk.shared sendGeolocationToChat:self.chatRoom.chatId longitude:coordinate.longitude latitude:coordinate.latitude image:imageB64];
        }
        MEGALogDebug(@"[Share Location] Send message %@", message);
        if (!message) {
            [SVProgressHUD showErrorWithStatus:@"Share location is not possible"];
        }
        
        [self dismissViewControllerAnimated:YES completion:^{
            [SVProgressHUD dismiss];
        }];
    }];
}

- (void)sendGeolocation:(UITapGestureRecognizer *)gesture {
    [self sendGeolocationWithCoordinate2d:self.mapView.centerCoordinate];
}

#pragma mark - IBAction

- (IBAction)infoButtonTouchUpInside:(UIButton *)sender {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"Map settings", @"Title of the alert that allows change between different maps: Standar, Satellite or Hybrid.") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    if (self.mapView.mapType != MKMapTypeStandard) {
        [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"chat.sendLocation.map.standard", @"Standard") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            self.mapView.mapType = MKMapTypeStandard;
        }]];
    }
    if (self.mapView.mapType != MKMapTypeSatellite) {
        [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"chat.sendLocation.map.satellite", @"Satellite") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            self.mapView.mapType = MKMapTypeSatellite;
        }]];
    }
    if (self.mapView.mapType != MKMapTypeHybrid) {
        [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"chat.sendLocation.map.hybrid", @"Hybrid") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            self.mapView.mapType = MKMapTypeHybrid;
        }]];
    }
    
    [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"cancel", @"Button title to cancel something") style:UIAlertActionStyleCancel handler:nil]];
    
    UIPopoverPresentationController *popoverPresentationController = [alertController popoverPresentationController];
    if (popoverPresentationController) {
        alertController.modalPresentationStyle = UIModalPresentationPopover;
        CGRect rect = CGRectMake(self.mapOptionsView.frame.origin.x, self.mapOptionsView.frame.origin.y, self.mapOptionsView.frame.size.width, self.mapOptionsView.frame.size.height - 45);
        popoverPresentationController.sourceRect = rect;
        popoverPresentationController.sourceView = self.view;
    }
    
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
    if (!self.editMessage) {
        MEGALogDebug(@"[Share Location] Did update locations %@", locations);
        self.locationManager.delegate = nil;
        
        CLLocation *location = locations.lastObject;
        CLLocationCoordinate2D center = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude);
        MKCoordinateRegion region = MKCoordinateRegionMake(center, MKCoordinateSpanMake(0.01, 0.01));
        
        [self.mapView setRegion:region animated:YES];
    }
}

#pragma mark - MKMapViewDelegate

#pragma mark - MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated {
    if (!self.pointAnnotation) {
        self.pointAnnotation = MKPointAnnotation.new;
        self.pointAnnotation.coordinate = mapView.region.center;
        [self.mapView addAnnotation:self.pointAnnotation];
    }
    [mapView selectAnnotation:self.pointAnnotation animated:YES];
}

- (void)mapViewDidChangeVisibleRegion:(MKMapView *)mapView {
    self.pointAnnotation.coordinate = mapView.region.center;
}

- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    [mapView deselectAnnotation:self.pointAnnotation animated:YES];
    
    CLLocation *location = [[CLLocation alloc] initWithLatitude:mapView.centerCoordinate.latitude longitude:mapView.centerCoordinate.longitude];

    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder reverseGeocodeLocation:location completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
        if (!error && placemarks.count > 0) {
            CLPlacemark *placemark = placemarks.firstObject;
            self.subtitleLabel.text = placemark.name;
        } else {
            self.subtitleLabel.text = [NSString stringWithFormat:LocalizedString(@"Accurate to %d meters", @"Label to give feedback to the user when he is going to share his location, indicating that it may not be the exact location."), (int)location.horizontalAccuracy];
        }
    }];
}

#pragma mark - LocationSearchTableViewControllerDelegate

- (void)didSelectPlacemark:(MKPlacemark *)placemark {
    [self sendGeolocationWithCoordinate2d:placemark.coordinate];
}

@end
