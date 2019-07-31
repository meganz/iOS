#import <UIKit/UIKit.h>

@interface UpgradeTableViewController : UIViewController

@property (nonatomic, getter=isChoosingTheAccountType) BOOL chooseAccountType;
@property (nonatomic, getter=shouldHideSkipButton) BOOL hideSkipButton;

@end
