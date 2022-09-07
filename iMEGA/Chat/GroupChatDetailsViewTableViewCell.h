#import <UIKit/UIKit.h>

@class GroupChatDetailsViewTableViewCell;
@protocol GroupChatDetailsViewTableViewCellDelegate <NSObject>
@optional
- (void)controlSwitchValueChanged:(UISwitch *)sender fromCell:(GroupChatDetailsViewTableViewCell *)cell;
@end

@interface GroupChatDetailsViewTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *leftImageView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *emailLabel;
@property (weak, nonatomic) IBOutlet UIView *onlineStatusView;
@property (weak, nonatomic) IBOutlet UIButton *permissionsButton;

@property (weak, nonatomic) IBOutlet UILabel *rightLabel;
@property (weak, nonatomic) IBOutlet UILabel *enableLabel;

@property (weak, nonatomic) IBOutlet UISwitch *controlSwitch;
@property (weak, nonatomic) id<GroupChatDetailsViewTableViewCellDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIImageView *verifiedImageView;

@property (nonatomic, setter=setDestructive:, getter=isDestructive) BOOL destructive;
@end
