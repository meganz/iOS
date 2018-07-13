#import <UIKit/UIKit.h>
#import "ChatRoomsType.h"

@interface ChatRoomsViewController : UIViewController

@property (assign, nonatomic) ChatRoomsType chatRoomsType;
- (void)openChatRoomWithID:(uint64_t)chatID;

@end
