#import <UIKit/UIKit.h>

typedef NS_ENUM (NSInteger, ChatRoomsType) {
    ChatRoomsTypeDefault        = 0,
    ChatRoomsTypeArchived
};

@interface ChatRoomsViewController : UIViewController

@property (assign, nonatomic) ChatRoomsType chatRoomsType;
- (void)openChatRoomWithID:(uint64_t)chatID;

@end
