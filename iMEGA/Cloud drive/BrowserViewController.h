#import <UIKit/UIKit.h>

#import "MEGASdkManager.h"

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
    BrowserActionNewFileSave
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
@property (nonatomic, strong) NSArray *selectedNodesArray;

@property (nonatomic) BrowserAction browserAction;
@property (nonatomic, getter=isChildBrowser) BOOL childBrowser;
@property (nonatomic, getter=isChildBrowserFromIncoming) BOOL childBrowserFromIncoming;

@property (nonatomic, strong) NSString *localpath;

@property (nonatomic, copy) void(^selectedNodes)(NSArray *);
@property (nonatomic, strong) NSMutableDictionary *selectedNodesMutableDictionary;

@property (nonatomic, weak) id<BrowserViewControllerDelegate> browserViewControllerDelegate;

- (void)pushBrowserWithParentNode:(MEGANode *)parentNode;

@end

