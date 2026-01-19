#import <UIKit/UIKit.h>

@interface AdvancedTableViewController : UITableViewController

@property (weak, nonatomic) IBOutlet UILabel *savePhotosLabel;
@property (weak, nonatomic) IBOutlet UILabel *saveVideosLabel;

@property (weak, nonatomic) IBOutlet UISwitch *saveImagesSwitch;
@property (weak, nonatomic) IBOutlet UIButton *saveImagesButton;
@property (weak, nonatomic) IBOutlet UISwitch *saveVideosSwitch;
@property (weak, nonatomic) IBOutlet UIButton *saveVideosButton;

@property (weak, nonatomic) IBOutlet UILabel *dontUseHttpLabel;
@property (weak, nonatomic) IBOutlet UISwitch *useHttpsOnlySwitch;

@property (weak, nonatomic) IBOutlet UILabel *saveMediaInGalleryLabel;
@property (weak, nonatomic) IBOutlet UISwitch *saveMediaInGallerySwitch;
@property (weak, nonatomic) IBOutlet UIButton *saveMediaInGalleryButton;

@end
