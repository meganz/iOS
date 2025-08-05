#import "LocationSearchTableViewController.h"

#import <MapKit/MapKit.h>

#import "LocationSearchTableViewCell.h"

#import "LocalizationHelper.h"

@interface LocationSearchTableViewController ()

@property (nonatomic) NSArray <MKMapItem *> *mapItems;

@end

@implementation LocationSearchTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = LocalizedString(@"Send Location", @"Alert title shown when the user opens a shared Geolocation for the first time from any client, we will show a confirmation dialog warning the user that he is now leaving the E2EE paradigm");
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.tableView.contentInset = UIEdgeInsetsMake(30, 0, 0, 0);
}

#pragma mark - Private

- (NSString *)addressWithPlacemark:(MKPlacemark *)placemark {
    NSString *firstSpace = (placemark.subThoroughfare && placemark.thoroughfare) ? @" " : @"";
    NSString *commna = ((placemark.subThoroughfare || placemark.thoroughfare) && (placemark.subAdministrativeArea || placemark.administrativeArea)) ? @", " : @"";
    NSString *secondSpace = (placemark.subAdministrativeArea && placemark.administrativeArea) ? @" " : @"";
    NSString *address = [NSString stringWithFormat:@"%@%@%@%@%@%@%@", placemark.subThoroughfare ?: @"", firstSpace, placemark.thoroughfare ?: @"", commna, placemark.locality ?: @"", secondSpace, placemark.administrativeArea ?: @""];
    
    return address;
}

#pragma mark - UISeachResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchText = searchController.searchBar.text;
    if (searchText) {
        MKLocalSearchRequest *searchRequest = [[MKLocalSearchRequest alloc] init];
        searchRequest.region = self.mapView.region;
        searchRequest.naturalLanguageQuery = searchText;
        
        MKLocalSearch *localSearch = [[MKLocalSearch alloc] initWithRequest:searchRequest];
        [localSearch startWithCompletionHandler:^(MKLocalSearchResponse *response, NSError *error) {
            if (!error) {
                for (MKMapItem *mapItem in [response mapItems]) {
                    MEGALogDebug(@"[Share Location] Name: %@, Placemark title: %@", [mapItem name], [[mapItem placemark] title]);
                }
                self.mapItems = response.mapItems;
            } else {
                MEGALogError(@"[Share Location] Search Request Error: %@", [error localizedDescription]);
            }
            [self.tableView reloadData];
        }];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.mapItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LocationSearchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"locationSearchCell" forIndexPath:indexPath];
    MKPlacemark *placemark = self.mapItems[indexPath.row].placemark;
    cell.titleLabel.text = placemark.name;
    cell.detailLabel.text = [self addressWithPlacemark:placemark];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MKPlacemark *placemark = self.mapItems[indexPath.row].placemark;
    [self dismissViewControllerAnimated:YES completion:nil];
    [self.delegate didSelectPlacemark:placemark];
}

@end
