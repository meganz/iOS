#import <UIKit/UIKit.h>
#import "ChatRoomsType.h"

@class MyAvatarManager, GlobalDNDNotificationControl, ContextMenuManager;

NS_ASSUME_NONNULL_BEGIN

@interface ChatRoomsViewController : UIViewController

@property (assign, nonatomic) ChatRoomsType chatRoomsType;
@property (nonatomic, strong, nullable) MyAvatarManager *myAvatarManager;
@property (nonatomic) GlobalDNDNotificationControl *globalDNDNotificationControl;

@property (strong, nonatomic) UIBarButtonItem *addBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *moreBarButtonItem;

@property (nonatomic, strong, nullable) ContextMenuManager *contextMenuManager;

- (void)openChatRoomWithID:(uint64_t)chatID;
- (void)openChatRoomWithPublicLink:(NSString *)publicLink chatID:(uint64_t)chatID;
- (void)showStartConversation;

@end

NS_ASSUME_NONNULL_END
