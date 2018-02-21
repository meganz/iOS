
#import <UIKit/UIKit.h>

@protocol NodeInfoViewControllerDelegate <NSObject>

- (void)presentParentNode:(MEGANode *)node inNavigation:(UINavigationController *)navigationController;

@end

@class MEGANode;

@interface NodeInfoViewController : UIViewController

@property (strong, nonatomic) MEGANode *node;

@property (weak, nonatomic) id<NodeInfoViewControllerDelegate> nodeInfoDelegate;

@end
