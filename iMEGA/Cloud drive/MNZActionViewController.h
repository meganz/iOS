
#import <UIKit/UIKit.h>
#import "CloudDriveTableViewController.h"

@interface MNZActionViewController : UIViewController

@property (strong, nonatomic) MEGANode *node;
@property (nonatomic) DisplayMode displayMode;
@property (nonatomic, getter=isIncomingShareChildView) BOOL incomingShareChildView;

@end
