#import <UIKit/UIKit.h>

@interface ContactTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIView *onlineStatusView;
@property (weak, nonatomic) IBOutlet UILabel *shareLabel;

@property (weak, nonatomic) IBOutlet UISwitch *notificationsSwitch;

@property (weak, nonatomic) IBOutlet UIImageView *permissionsImageView;

@property (weak, nonatomic) IBOutlet UIButton *infoButton;

@property (weak, nonatomic) IBOutlet UIView *lineView;

@end
