#import <UIKit/UIKit.h>

@class BrowserViewModel;

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

@property (nonatomic, strong) MEGANode *parentNode;
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

@property (weak, nonatomic) IBOutlet UIView *selectorView;
@property (weak, nonatomic) IBOutlet UIView *cloudDriveLineView;
@property (weak, nonatomic) IBOutlet UIView *incomingLineView;

@property (nonatomic, strong) UIViewController *shimmerViewController;

- (void)pushBrowserWithParentNode:(MEGANode *)parentNode;
- (void)updatePromptTitle;
- (void)attachNodes;

@end

