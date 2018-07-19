
#import <UIKit/UIKit.h>

#import "MEGAChatListItem.h"
#import "SendMode.h"

@protocol SendToViewControllerDelegate <NSObject>
- (void)sendToChats:(NSArray<MEGAChatListItem *> *)chats andUsers:(NSArray<MEGAUser *> *)users;
@end

@interface SendToViewController : UIViewController

@property (strong, nonatomic) NSArray *nodes;
@property (nonatomic) SendMode sendMode;

@property (nonatomic, weak) id<SendToViewControllerDelegate> sendToViewControllerDelegate;

@end
