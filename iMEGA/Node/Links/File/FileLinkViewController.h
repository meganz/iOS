#import <UIKit/UIKit.h>

@class ContextMenuManager;
@class SendLinkToChatsDelegate;

@interface FileLinkViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIBarButtonItem *moreBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareLinkBarButtonItem;

@property (strong, nonatomic) MEGANode *node;
@property (nonatomic, strong) NSString *publicLinkString;
@property (nonatomic, strong) NSString *linkEncryptedString;

@property (nonatomic, strong) MEGARequest *request;
@property (nonatomic, strong) MEGAError *error;
@property (nonatomic, strong) ContextMenuManager * contextMenuManager;
@property (nonatomic) SendLinkToChatsDelegate *sendLinkDelegate;

- (void)importFromFiles;

@end
