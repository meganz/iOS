#import <UIKit/UIKit.h>
#import "MEGASdkManager.h"

typedef NS_ENUM (NSInteger, DisplayMode) {
    DisplayModeCloudDrive = 0,
    DisplayModeRubbishBin,
    DisplayModeSharedItem,
    DisplayModeNodeInfo
};

@interface CloudDriveTableViewController : UITableViewController

@property (nonatomic, strong) MEGANode *parentNode;
@property (nonatomic, strong) MEGAUser *user;
@property (nonatomic) DisplayMode displayMode;
@property (nonatomic, getter=isIncomingShareChildView) BOOL incomingShareChildView;
@property (nonatomic) BOOL homeQuickActionSearch;

- (void)activateSearch;
- (void)presentUploadAlertController;

@end
