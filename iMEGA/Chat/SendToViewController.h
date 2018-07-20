
#import <UIKit/UIKit.h>

#import "MEGAChatListItem.h"
#import "MEGAChatMessage.h"
#import "SendMode.h"

@protocol SendToViewControllerDelegate <NSObject>
- (void)sendToChats:(NSArray<MEGAChatListItem *> *)chats andUsers:(NSArray<MEGAUser *> *)users;
@end

@interface SendToViewController : UIViewController

@property (nonatomic) NSArray *nodes;
@property (nonatomic) NSArray<MEGAChatMessage *> *messages;
@property (nonatomic) SendMode sendMode;
@property (nonatomic) void (^completion)(NSArray<NSNumber *> *chatIdNumbers, NSArray<MEGAChatMessage *> *sentMessages);
@property (nonatomic) uint64_t sourceChatId;

@property (nonatomic, weak) id<SendToViewControllerDelegate> sendToViewControllerDelegate;

@end
