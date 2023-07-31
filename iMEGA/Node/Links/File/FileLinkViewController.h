#import <UIKit/UIKit.h>

@class ContextMenuManager;
@class SendLinkToChatsDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface FileLinkViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIBarButtonItem *moreBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareLinkBarButtonItem;

@property (strong, nonatomic, nullable) MEGANode *node;
@property (nonatomic, strong, nullable) NSString *publicLinkString;
@property (nonatomic, strong, nullable) NSString *linkEncryptedString;

@property (nonatomic, strong) MEGARequest *request;
@property (nonatomic, strong) MEGAError *error;
@property (nonatomic, strong, nullable) ContextMenuManager * contextMenuManager;
@property (nonatomic) SendLinkToChatsDelegate *sendLinkDelegate;

- (void)importFromFiles;

@end

NS_ASSUME_NONNULL_END
