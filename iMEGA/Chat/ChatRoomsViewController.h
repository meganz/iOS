#import <UIKit/UIKit.h>
#import "ChatRoomsType.h"

@class MyAvatarManager;

@interface ChatRoomsViewController : UIViewController

@property (assign, nonatomic) ChatRoomsType chatRoomsType;
@property (nonatomic, strong) MyAvatarManager * _Nullable myAvatarManager;

- (void)openChatRoomWithID:(uint64_t)chatID;
- (void)openChatRoomWithPublicLink:(NSString *)publicLink chatID:(uint64_t)chatID;
- (void)showStartConversation;

@end
