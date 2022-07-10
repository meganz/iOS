#import <UIKit/UIKit.h>
#import "ChatRoomsType.h"

@class MyAvatarManager, GlobalDNDNotificationControl, ContextMenuManager, MEGAVerticalButton;

NS_ASSUME_NONNULL_BEGIN

@interface ChatRoomsViewController : UIViewController

@property (assign, nonatomic) ChatRoomsType chatRoomsType;
@property (nonatomic, strong, nullable) MyAvatarManager *myAvatarManager;
@property (nonatomic) GlobalDNDNotificationControl *globalDNDNotificationControl;

@property (strong, nonatomic) UIBarButtonItem *addBarButtonItem;
@property (strong, nonatomic) UIBarButtonItem *moreBarButtonItem;

@property (nonatomic, strong, nullable) ContextMenuManager *contextMenuManager;

- (void)openChatRoomWithID:(uint64_t)chatID;
- (void)openChatRoomWithPublicLink:(NSString *)publicLink chatID:(uint64_t)chatID;
- (void)showStartConversation;


@property (weak, nonatomic) IBOutlet UIView *chatOrMeetingSelectorView;
@property (weak, nonatomic) IBOutlet MEGAVerticalButton *chatSelectorButton;
@property (weak, nonatomic) IBOutlet UIView *chatSelectedView;
@property (weak, nonatomic) IBOutlet MEGAVerticalButton *meetingSelectorButton;
@property (weak, nonatomic) IBOutlet UIView *meetingSelectedView;

@property (strong, nonatomic) UISearchController *searchController;

- (void)reloadData;

@end

NS_ASSUME_NONNULL_END
