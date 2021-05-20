#import <UIKit/UIKit.h>

#import "DisplayMode.h"

@class MEGANode;
@class MEGAUser;
@class MyAvatarManager;

static const NSUInteger kMinimumLettersToStartTheSearch = 1;

@interface CloudDriveViewController : UIViewController

@property (nonatomic, strong) MEGANode *parentNode;
@property (nonatomic, strong) MEGAUser *user;
@property (nonatomic) DisplayMode displayMode;
@property (nonatomic, getter=isIncomingShareChildView) BOOL incomingShareChildView;

@property (nonatomic, strong) MEGANodeList *nodes;
@property (nonatomic, strong) NSMutableArray<MEGANode *> *searchNodesArray;
@property (nonatomic, strong, nullable) NSMutableArray<MEGANode *> *selectedNodesArray;
@property (nonatomic, strong) NSMutableDictionary *nodesIndexPathMutableDictionary;

@property (nonatomic, strong) MEGARecentActionBucket *recentActionBucket;

@property (strong, nonatomic) UISearchController *searchController;

@property (assign, nonatomic) BOOL allNodesSelected;
@property (assign, nonatomic) BOOL shouldRemovePlayerDelegate;

@property (nonatomic, strong) MyAvatarManager * _Nullable myAvatarManager;

- (void)presentUploadAlertController;
- (void)presentScanDocument;
- (void)setViewEditing:(BOOL)editing;
- (void)updateNavigationBarTitle;
- (void)toolbarActionsForNodeArray:(NSArray *)nodeArray;
- (void)setToolbarActionsEnabled:(BOOL)boolValue;
- (void)showCustomActionsForNode:(MEGANode *)node sender:(UIButton *)sender;
- (void)didSelectNode:(MEGANode *)node;
- (void)confirmDeleteActionFiles:(NSUInteger)numFilesAction andFolders:(NSUInteger)numFoldersAction;
- (void)setEditMode:(BOOL)editMode;
- (nullable MEGANode *)nodeAtIndexPath:(NSIndexPath *)indexPath;

@end
