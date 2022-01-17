#import <UIKit/UIKit.h>

@protocol GroupChatDetailsViewTableViewCellDelegate <NSObject>
@optional
- (void)notificationSwitchValueChanged:(UISwitch *)sender;
@end

@interface GroupChatDetailsViewTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *leftImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;
@property (weak, nonatomic) IBOutlet UIView *onlineStatusView;
@property (weak, nonatomic) IBOutlet UIButton *permissionsButton;

@property (weak, nonatomic) IBOutlet UILabel *rightLabel;
@property (weak, nonatomic) IBOutlet UILabel *enableLabel;

@property (weak, nonatomic) IBOutlet UISwitch *notificationsSwitch;
@property (weak, nonatomic) id<GroupChatDetailsViewTableViewCellDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIImageView *verifiedImageView;

@property (nonatomic, setter=setDestructive:, getter=isDestructive) BOOL destructive;
@end
