#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, ContactsMode) {
    ContactsModeDefault = 0,
    ContactsModeShareFoldersWith = 1,
    ContactsModeFolderSharedWith = 2,
    ContactsModeChatStartConversation = 3,
    ContactsModeChatAddParticipant = 4,
    ContactsModeChatAttachParticipant = 5,
    ContactsModeChatCreateGroup = 6,
    ContactsModeChatNamingGroup = 7,
    ContactsModeInviteParticipants = 8,
    ContactsModeScheduleMeeting = 9
};

typedef NS_ENUM(NSUInteger, ChatOptionType) {
    ChatOptionTypeNone = 0,
    ChatOptionTypeMeeting = 1,
    ChatOptionTypeNonMeeting = 2
};

@protocol ContactsViewControllerDelegate <NSObject>
@optional
- (void)nodeEditCompleted:(BOOL)complete;
@end

@class ItemListModel, UserEntity, ContactsViewModel;

@interface ContactsViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareFolderWithBarButtonItem;

@property (weak, nonatomic) IBOutlet UIView *contactsNotVerifiedView;

@property (weak, nonatomic) IBOutlet UIView *itemListView;
@property (weak, nonatomic) IBOutlet UIView *chatNamingGroupTableViewHeader;
@property (weak, nonatomic) IBOutlet UIView *enterGroupNameView;
@property (weak, nonatomic) IBOutlet UIView *enterGroupNameBottomSeparatorView;
@property (weak, nonatomic) IBOutlet UIView *encryptedKeyRotationView;
@property (weak, nonatomic) IBOutlet UIView *encryptedKeyRotationTopSeparatorView;
@property (weak, nonatomic) IBOutlet UIView *encryptedKeyRotationBottomSeparatorView;
@property (weak, nonatomic) IBOutlet UIView *getChatLinkView;
@property (weak, nonatomic) IBOutlet UIView *getChatLinkTopSeparatorView;
@property (weak, nonatomic) IBOutlet UIView *getChatLinkBottomSeparatorView;
@property (weak, nonatomic) IBOutlet UIView *allowNonHostToAddParticipantsView;
@property (weak, nonatomic) IBOutlet UIView *allowNonHostToAddParticipantsTopSeparatorView;
@property (weak, nonatomic) IBOutlet UIView *allowNonHostToAddParticipantsBottomSeparatorView;
@property (weak, nonatomic) IBOutlet UIImageView *addGroupAvatarImageView;

@property (nonatomic) ContactsMode contactsMode;
@property (nonatomic) ChatOptionType chatOptionType;
@property (strong, nonatomic) ContactsViewModel*viewModel;

@property (nonatomic) BOOL avoidPresentIncomingPendingContactRequests;

@property (nonatomic, strong) MEGANode *node;
@property (nonatomic, strong) NSArray *nodesArray;
@property (nonatomic, strong) NSMutableArray *selectedUsersArray;
@property (nonatomic, strong) NSMutableArray<MEGAUser *> *visibleUsersArray;
@property (strong, nonatomic) UISearchController *searchController;

@property (nonatomic, copy) void(^userSelected)(NSArray<MEGAUser *> *);
@property (nonatomic, copy) void(^chatSelected)(uint64_t);
@property (nonatomic, copy) void(^createGroupChat)(NSArray *,  NSString *, BOOL, BOOL, BOOL);

@property (strong, nonatomic) NSMutableDictionary *participantsMutableDictionary;
@property (strong, nonatomic) NSSet<id> *subscriptions;
@property (nonatomic, weak) id<ContactsViewControllerDelegate> contactsViewControllerDelegate;

- (void)shareNodesWithLevel:(MEGAShareType)shareType nodes:(NSArray *)nodes;
- (void)shareNodesWithLevel:(MEGAShareType)shareType;
- (void)selectPermissionsFromButton:(UIBarButtonItem *)sourceButton;
- (void)addItemsToList:(NSArray<ItemListModel *> *)items;
- (void)reloadUI;

@end
