#import <UIKit/UIKit.h>


typedef NS_ENUM(NSUInteger, ContactsStartConversation) {
    ContactsStartConversationNewGroupChat = 0,
    ContactsStartConversationNewMeeting,
    ContactsStartConversationJoinMeeting
};

@protocol ContactTableViewCellDelegate<NSObject>
@optional
- (void)notificationSwitchValueChanged:(UISwitch *)sender;

@end

@interface ContactTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIView *onlineStatusView;
@property (weak, nonatomic) IBOutlet UILabel *shareLabel;

@property (weak, nonatomic) IBOutlet UISwitch *notificationsSwitch;

@property (weak, nonatomic) IBOutlet UIImageView *permissionsImageView;
@property (weak, nonatomic) IBOutlet UILabel *permissionsLabel;

@property (weak, nonatomic) IBOutlet UIView *contactNewView;
@property (weak, nonatomic) IBOutlet UIView *contactNewLabelView;
@property (weak, nonatomic) IBOutlet UILabel *contactNewLabel;

@property (weak, nonatomic) IBOutlet UIButton *contactDetailsButton;

@property (weak, nonatomic) IBOutlet UIButton *infoButton;

@property (weak, nonatomic) IBOutlet UITextField *groupNameTextField;
@property (weak, nonatomic) IBOutlet UIImageView *verifiedImageView;

@property (weak, nonatomic) id<ContactTableViewCellDelegate> delegate;

- (void)configureDefaultCellForUser:(MEGAUser *)user newUser:(BOOL)newUser;
- (void)configureCellForContactsModeChatStartConversation:(ContactsStartConversation)option;
- (void)configureCellForContactsModeFolderSharedWith:(MEGAUser *)user indexPath:(NSIndexPath *)indexPath;

@end
