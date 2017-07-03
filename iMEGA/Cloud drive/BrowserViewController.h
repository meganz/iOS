#import <UIKit/UIKit.h>

#import "MEGASdkManager.h"

typedef NS_ENUM(NSUInteger, BrowserAction) {
    BrowserActionCopy = 0,
    BrowserActionMove,
    BrowserActionImport,
    BrowserActionImportFromFolderLink,
    BrowserActionOpenIn,
    BrowserActionSendFromCloudDrive,
    BrowserActionDocumentProvider
};

@protocol BrowserViewControllerDelegate <NSObject>
- (void)didSelectNode:(MEGANode *)node;
@end

@interface BrowserViewController : UIViewController

@property (nonatomic, strong) MEGANode *parentNode;
@property (nonatomic, strong) NSArray *selectedNodesArray;

@property (nonatomic) BrowserAction browserAction;
@property (nonatomic, getter=isChildBrowser) BOOL childBrowser;
@property (nonatomic, getter=isChildBrowserFromIncoming) BOOL childBrowserFromIncoming;

@property (nonatomic, strong) NSString *localpath;

@property (nonatomic, copy) void(^selectedNodes)(NSArray *);
@property (nonatomic, strong) NSMutableDictionary *selectedNodesMutableDictionary;

@property (nonatomic, weak) id <BrowserViewControllerDelegate> browserViewControllerDelegate;

@end

