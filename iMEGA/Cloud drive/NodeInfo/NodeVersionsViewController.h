
#import <UIKit/UIKit.h>

@interface NodeVersionsViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIBarButtonItem *downloadBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *revertBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *removeBarButtonItem;

@property (strong, nonatomic) MEGANode *node;
@property (nonatomic, strong) NSMutableArray<MEGANode *> *selectedNodesArray;

@end
