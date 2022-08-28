#import <UIKit/UIKit.h>

@interface CameraUploadsTableViewController : UITableViewController

@property (nonatomic) BOOL isPresentedModally;
@property (copy) void (^cameraUploadSettingChanged)(void);
@end
