
#import <UIKit/UIKit.h>

#import "DisplayMode.h"
#import "MegaNodeActionType.h"

@protocol CustomActionViewControllerDelegate <NSObject>

- (void)performAction:(MegaNodeActionType)action inNode:(MEGANode *)node fromSender:(id)sender;

@end

@interface CustomActionViewController : UIViewController <UIPopoverPresentationControllerDelegate>

@property (strong, nonatomic) MEGANode *node;
@property (nonatomic) DisplayMode displayMode;
@property (nonatomic, getter=isIncomingShareChildView) BOOL incomingShareChildView;
@property (weak, nonatomic) id<CustomActionViewControllerDelegate> actionDelegate;
@property (nonatomic, strong) id actionSender;
@property (strong, nonatomic) NSArray *excludedActions;

@end

