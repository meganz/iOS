#import <UIKit/UIKit.h>
#import "MEGAChatSdk.h"

typedef NS_ENUM (NSInteger, ContactDetailsMode) {
    ContactDetailsModeDefault = 0,
    ContactDetailsModeFromChat,
    ContactDetailsModeFromGroupChat,
    ContactDetailsModeMeeting
};

@interface ContactDetailsViewController : UIViewController

@property (nonatomic) ContactDetailsMode contactDetailsMode;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *callButton;
@property (weak, nonatomic) IBOutlet UIButton *videoCallButton;
@property (weak, nonatomic) IBOutlet UIButton *messageButton;
@property (weak, nonatomic) IBOutlet UILabel *messageLabel;
@property (weak, nonatomic) IBOutlet UILabel *callLabel;
@property (weak, nonatomic) IBOutlet UILabel *videoLabel;
@property (weak, nonatomic) IBOutlet UIView *actionsView;
@property (weak, nonatomic) IBOutlet UIView *actionsBottomSeparatorView;
@property (strong, nonatomic) MEGANodeList *incomingNodeListForUser;
@property (nonatomic, strong) NSString *userEmail;
@property (nonatomic, strong) NSString *userName;
@property (nonatomic) uint64_t userHandle;
@property (nonatomic) MEGAChatRoom *groupChatRoom; // Used to change contacts permissions or remove as participant in the group chat
@property (nonatomic, copy) void (^didUpdatePeerPermission)(MEGAChatRoomPrivilege peerPrivilege);
@property (assign, nonatomic, getter=isUserActionInProgress) BOOL userActionInProgress;

@end
