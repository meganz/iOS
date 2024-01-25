#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CameraUploadAdvancedOptionsViewController : UITableViewController

@property (weak, nonatomic) IBOutlet UISwitch *uploadVideosForlivePhotosSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *uploadSharedAlbumsSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *uploadSyncedAlbumsSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *uploadHiddenAlbumSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *uploadAllBurstPhotosSwitch;

@end

NS_ASSUME_NONNULL_END
