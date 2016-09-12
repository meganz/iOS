#import <UIKit/UIKit.h>
#import "MEGASdkManager.h"
#import "CloudDriveTableViewController.h"

@interface DetailsNodeInfoViewController : UIViewController 

@property (nonatomic, strong) MEGANode *node;
@property (nonatomic) DisplayMode displayMode;

@property (nonatomic, strong) NSString *userName;
@property (nonatomic, strong) NSString *email;

@end
