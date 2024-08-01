#import <UIKit/UIKit.h>

#import "MEGAChatListItem.h"
#import "MEGAChatMessage.h"
#import "SendMode.h"

@class SendToViewController;

@protocol SendToViewControllerDelegate <NSObject>
- (void)sendToViewController:(SendToViewController *)viewController toChats:(NSArray<MEGAChatListItem *> *)chats andUsers:(NSArray<MEGAUser *> *)users;
@end

@protocol SendToChatActivityDelegate <NSObject>
- (void)sendToViewController:(SendToViewController *)viewController didFinishActivity:(BOOL)completed;
- (NSString *)textToSend;
@end

@interface SendToViewController : UIViewController

@property (nonatomic) NSArray *nodes;
@property (nonatomic) NSArray<MEGAChatMessage *> *messages;
@property (nonatomic) SendMode sendMode;
@property (nonatomic) void (^completion)(NSArray<NSNumber *> *chatIdNumbers, NSArray<MEGAChatMessage *> *sentMessages);
@property (nonatomic) uint64_t sourceChatId;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, weak) id<SendToViewControllerDelegate> sendToViewControllerDelegate;
@property (nonatomic, weak) id<SendToChatActivityDelegate> sendToChatActivityDelegate;

- (NSUInteger)selectedChatCount;

@end
