
#import <UIKit/UIKit.h>

@protocol NodeInfoViewControllerDelegate <NSObject>

- (void)presentParentNode:(MEGANode *)node;

@end

@class MEGANode;

@interface NodeInfoViewController : UIViewController

@property (strong, nonatomic) MEGANode *node;

@property (weak, nonatomic) id<NodeInfoViewControllerDelegate> nodeInfoDelegate;

@property (nonatomic, getter=isIncomingShareChildView) BOOL incomingShareChildView;

@end
