
#import <UIKit/UIKit.h>
#import "CloudDriveTableViewController.h"
#import "MEGANode+MNZCategory.h"
#import "MegaNodeActionType.h"

@protocol CustomActionViewControllerDelegate <NSObject>

- (void)performAction:(MegaNodeActionType)action inNode:(MEGANode *)node;

@end

@interface CustomActionViewController : UIViewController <UIPopoverPresentationControllerDelegate>

@property (strong, nonatomic) MEGANode *node;
@property (nonatomic) DisplayMode displayMode;
@property (nonatomic, getter=isIncomingShareChildView) BOOL incomingShareChildView;
@property (weak, nonatomic) id<CustomActionViewControllerDelegate> actionDelegate;

@end

