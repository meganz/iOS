#import <UIKit/UIKit.h>

#import "MEGASdkManager.h"

typedef NS_ENUM(NSUInteger, GroupChatDetailsSection) {
    GroupChatDetailsSectionChatNotifications = 0,
    GroupChatDetailsSectionAllowNonHostToAddParticipants,
    GroupChatDetailsSectionRenameGroup,
    GroupChatDetailsSectionSharedFiles,
    GroupChatDetailsSectionGetChatLink,
    GroupChatDetailsSectionManageChatHistory,
    GroupChatDetailsSectionArchiveChat,
    GroupChatDetailsSectionLeaveGroup,
    GroupChatDetailsSectionEndCallForAll,
    GroupChatDetailsSectionEncryptedKeyRotation,
    GroupChatDetailsSectionObservers,
    GroupChatDetailsSectionParticipants,
};

@class EndCallDialog, ChatNotificationControl;

@interface GroupChatDetailsViewController : UIViewController

@property (nonatomic, strong) MEGAChatRoom *chatRoom;
@property (nonatomic, strong) EndCallDialog *endCallDialog;
@property (nonatomic, strong) ChatNotificationControl *chatNotificationControl;
@property (nonatomic, strong) NSArray<NSNumber *> *groupDetailsSections;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

- (void)reloadData;

@end
