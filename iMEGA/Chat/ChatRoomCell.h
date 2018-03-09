#import <UIKit/UIKit.h>

@interface ChatRoomCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;
@property (weak, nonatomic) IBOutlet UILabel *chatTitle;
@property (weak, nonatomic) IBOutlet UILabel *chatLastMessage;
@property (weak, nonatomic) IBOutlet UILabel *chatLastTime;
@property (weak, nonatomic) IBOutlet UIView *onlineStatusView;
@property (weak, nonatomic) IBOutlet UILabel *unreadCount;
@property (weak, nonatomic) IBOutlet UIView *unreadView;

@property (weak, nonatomic) IBOutlet UIView *lineView;

@end
