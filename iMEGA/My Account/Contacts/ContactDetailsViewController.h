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
@property (strong, nonatomic) MEGANodeList *incomingNodeListForUser;
@property (nonatomic, strong) NSString *userEmail;
@property (nonatomic, strong) NSString *userName;
@property (nonatomic) uint64_t userHandle;
@property (nonatomic) MEGAChatRoom *groupChatRoom; // Used to change contacts permissions or remove as participant in the group chat

@property (nonatomic, copy) void (^didUpdatePeerPermission)(MEGAChatRoomPrivilege peerPrivilege);

@end
