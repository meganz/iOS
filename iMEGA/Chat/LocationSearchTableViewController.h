#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol LocationSearchTableViewControllerDelegate <NSObject>

- (void)didSelectPlacemark:(MKPlacemark *)placemark;

@end

@interface LocationSearchTableViewController : UITableViewController <UISearchResultsUpdating>

@property (nonatomic) MKMapView *mapView;
@property (nonatomic) id<LocationSearchTableViewControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
