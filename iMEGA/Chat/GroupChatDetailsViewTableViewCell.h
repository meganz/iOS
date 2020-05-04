#import <UIKit/UIKit.h>

@interface GroupChatDetailsViewTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *leftImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;
@property (weak, nonatomic) IBOutlet UIView *onlineStatusView;
@property (weak, nonatomic) IBOutlet UIButton *permissionsButton;

@property (weak, nonatomic) IBOutlet UILabel *rightLabel;
@property (weak, nonatomic) IBOutlet UILabel *enableLabel;

@property (weak, nonatomic) IBOutlet UISwitch *notificationsSwitch;

@property (weak, nonatomic) IBOutlet UIImageView *verifiedImageView;

@end
