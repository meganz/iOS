
#import <UIKit/UIKit.h>

@class MEGANode;

@interface NodeInfoViewController : UIViewController

@property (strong, nonatomic) MEGANode *node;

- (void)configureCloseBarButton;

@end
