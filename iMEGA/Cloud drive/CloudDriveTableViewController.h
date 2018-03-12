
#import <UIKit/UIKit.h>

#import "DisplayMode.h"

@class MEGANode;
@class MEGAUser;

@interface CloudDriveTableViewController : UITableViewController

@property (nonatomic, strong) MEGANode *parentNode;
@property (nonatomic, strong) MEGAUser *user;
@property (nonatomic) DisplayMode displayMode;
@property (nonatomic, getter=isIncomingShareChildView) BOOL incomingShareChildView;
@property (nonatomic) BOOL homeQuickActionSearch;

- (void)activateSearch;
- (void)presentUploadAlertController;

@end
