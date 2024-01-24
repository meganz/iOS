#import <UIKit/UIKit.h>
@class NodeVersionSection;
@interface NodeVersionsViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIBarButtonItem *downloadBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *revertBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *removeBarButtonItem;
@property (nonatomic, strong) NSArray<NodeVersionSection *> *sections;
@property (strong, nonatomic) MEGANode *node;
@property (nonatomic, strong) NSMutableArray<MEGANode *> *selectedNodesArray;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@end
