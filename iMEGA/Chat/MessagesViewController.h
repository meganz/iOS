#import <UIKit/UIKit.h>
#import "JSQMessages.h"
#import "MEGASdkManager.h"

@interface MessagesViewController : JSQMessagesViewController <MEGAChatRoomDelegate>

@property (nonatomic, strong) MEGAChatRoom *chatRoom;
- (void)updateUnreadLabel;

@end
