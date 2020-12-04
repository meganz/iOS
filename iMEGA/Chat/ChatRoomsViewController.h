#import <UIKit/UIKit.h>
#import "ChatRoomsType.h"

@interface ChatRoomsViewController : UIViewController

@property (assign, nonatomic) ChatRoomsType chatRoomsType;
- (void)openChatRoomWithID:(uint64_t)chatID;
- (void)openChatRoomWithPublicLink:(NSString *)publicLink chatID:(uint64_t)chatID;
- (void)showStartConversation;

@end
