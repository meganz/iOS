#import <UIKit/UIKit.h>

@class CameraUploadsSettingsViewModel;

@interface CameraUploadsTableViewController : UITableViewController

@property (weak, nonatomic) IBOutlet UILabel *enableCameraUploadsLabel;
@property (weak, nonatomic) IBOutlet UILabel *uploadVideosInfoLabel;
@property (weak, nonatomic) IBOutlet UILabel *uploadVideosInfoRightDetailLabel;
@property (weak, nonatomic) IBOutlet UILabel *uploadVideosLabel;
@property (weak, nonatomic) IBOutlet UILabel *HEICLabel;
@property (weak, nonatomic) IBOutlet UILabel *JPGLabel;
@property (weak, nonatomic) IBOutlet UILabel *includeGPSTagsLabel;
@property (weak, nonatomic) IBOutlet UILabel *useCellularConnectionLabel;
@property (weak, nonatomic) IBOutlet UILabel *useCellularConnectionForVideosLabel;
@property (weak, nonatomic) IBOutlet UILabel *advancedLabel;
@property (weak, nonatomic) IBOutlet UILabel *targetFolderLabel;

@property (nonatomic) BOOL isPresentedModally;
@property (copy) void (^cameraUploadSettingChanged)(void);

@property (strong, nonatomic) CameraUploadsSettingsViewModel *viewModel;

@end
