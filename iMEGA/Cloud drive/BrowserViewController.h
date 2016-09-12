#import <UIKit/UIKit.h>

#import "MEGASdkManager.h"

typedef NS_ENUM(NSUInteger, BrowserAction) {
    BrowserActionCopy = 0,
    BrowserActionMove,
    BrowserActionImport,
    BrowserActionImportFromFolderLink,
    BrowserActionSelectFolderToShare,
    BrowserActionOpenIn
};

@interface BrowserViewController : UIViewController

@property (nonatomic, strong) MEGANode *parentNode;
@property (nonatomic, strong) NSArray *selectedNodesArray;
@property (nonatomic, strong) NSArray *selectedUsersArray;

@property (nonatomic) BrowserAction browserAction;
@property (nonatomic, getter=isChildBrowser) BOOL childBrowser;

@property (nonatomic, strong) NSString *localpath;

@end
