#import <UIKit/UIKit.h>

@interface FolderLinkViewController : UIViewController

@property (nonatomic) BOOL isFolderRootNode;
@property (nonatomic, strong) NSString *publicLinkString;
@property (nonatomic, strong) NSString *linkEncryptedString;

@property (strong, nonatomic) UISearchController *searchController;

@property (nonatomic, strong) NSArray<MEGANode *> *nodesArray;
@property (nonatomic, strong) NSArray<MEGANode *> *searchNodesArray;
@property (nonatomic, strong) NSMutableArray<MEGANode *> *selectedNodesArray;

@property (nonatomic, getter=isFolderLinkNotValid) BOOL folderLinkNotValid;
@property (nonatomic, getter=areAllNodesSelected) BOOL allNodesSelected;

- (void)didSelectNode:(MEGANode *)node;
- (void)showActionsForNode:(MEGANode *)node from:(UIButton *)sender;
- (void)setNavigationBarTitleLabel;
- (void)setToolbarButtonsEnabled:(BOOL)boolValue;
- (void)setViewEditing:(BOOL)editing;

@end
