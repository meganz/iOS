#import <UIKit/UIKit.h>

@class CameraUploadsAdvancedOptionsViewModel;

NS_ASSUME_NONNULL_BEGIN

@interface CameraUploadAdvancedOptionsViewController : UITableViewController

@property (weak, nonatomic) IBOutlet UISwitch *uploadVideosForlivePhotosSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *uploadSharedAlbumsSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *uploadSyncedAlbumsSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *uploadHiddenAlbumSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *uploadAllBurstPhotosSwitch;

@property (strong, nonatomic) CameraUploadsAdvancedOptionsViewModel *viewModel;

@end

NS_ASSUME_NONNULL_END
