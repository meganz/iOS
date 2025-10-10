#import <UIKit/UIKit.h>

@class BrowserViewModel, SharedItemsNodeSearcher;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, BrowserAction) {
    BrowserActionCopy = 0,
    BrowserActionMove,
    BrowserActionImport,
    BrowserActionImportFromFolderLink,
    BrowserActionOpenIn,
    BrowserActionSendFromCloudDrive,
    BrowserActionDocumentProvider,
    BrowserActionShareExtension,
    BrowserActionSelectFolder,
    BrowserActionNewHomeUpload,
    BrowserActionNewFileSave,
    BrowserActionSaveToCloudDrive,
    BrowserActionSelectVideo // A BrowserAction type specific for video picker selection.
};

@protocol BrowserViewControllerDelegate <NSObject>
@optional
- (void)didSelectNode:(MEGANode *)node;
- (void)uploadToParentNode:(MEGANode *)parentNode;
- (void)nodeEditCompleted:(BOOL)complete;
@end

@interface BrowserViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIButton *cloudDriveButton;

@property (weak, nonatomic) IBOutlet UIButton *incomingButton;

@property (nonatomic, strong, nullable) MEGANode *parentNode;
@property (nonatomic, strong) NSArray<MEGANode *> *selectedNodesArray;

@property (nonatomic) BrowserAction browserAction;
@property (nonatomic, getter=isChildBrowser) BOOL childBrowser;
@property (nonatomic, getter=isChildBrowserFromIncoming) BOOL childBrowserFromIncoming;

@property (nonatomic, strong) NSString *localpath;

@property (nonatomic, copy) void(^selectedNodes)(NSArray *);
@property (nonatomic, strong) NSMutableDictionary *selectedNodesMutableDictionary;

@property (nonatomic, weak) id<BrowserViewControllerDelegate> browserViewControllerDelegate;

@property (nonatomic, getter=isParentBrowser) BOOL parentBrowser;

@property (nonatomic) MEGAShareType parentShareType;
@property (strong, nonatomic) BrowserViewModel *viewModel;
@property (nonatomic, nullable) NSMutableArray<MEGANode *> *searchNodesArray;
@property (nonatomic) UISearchController *searchController;
@property (nonatomic, strong, nullable) SharedItemsNodeSearcher *nodeSearcher;

@property (nonatomic, strong, nullable) MEGANodeList *nodes;

@property (weak, nonatomic) IBOutlet UIView *selectorView;
@property (weak, nonatomic) IBOutlet UIView *cloudDriveLineView;
@property (weak, nonatomic) IBOutlet UIView *incomingLineView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong, nullable) UIViewController *shimmerViewController;

@property (nonatomic) NSUInteger remainingOperations;
@property (nonatomic, copy, nullable) void (^onCopyNodesCompletion)(void);

- (void)pushBrowserWithParentNode:(MEGANode *)parentNode;
- (void)updatePromptTitle;
- (void)attachNodes;
- (void)reloadUI;

- (IBAction)cloudDriveTouchUpInside:(UIButton *)sender;
- (IBAction)incomingTouchUpInside:(UIButton *)sender;
- (void)dismissAndSelectNodesIfNeeded:(BOOL)selectNodes completion:(void (^ __nullable)(void))completion;

@end

NS_ASSUME_NONNULL_END
