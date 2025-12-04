#import <UIKit/UIKit.h>

@interface PreviewDocumentViewController : UIViewController

@property (nonatomic, strong) MEGANode *node;
@property (nonatomic) uint64_t nodeHandle;
@property (nonatomic, strong) MEGASdk *api;
@property (nonatomic, strong) NSString *filePath;
@property (nonatomic) BOOL isLink;
@property (nonatomic) NSString *fileLink;
@property (nonatomic) BOOL isFromSharedItem;
@property (nonatomic) BOOL showUnknownEncodeHud;
@property (nonatomic) MEGAHandle chatId;
@property (nonatomic) MEGAHandle messageId;

- (void)sendToChatWhenLogin;

@end
