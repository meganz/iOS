#import <UIKit/UIKit.h>

#import "JSQMessagesLoadEarlierHeaderView.h"

@interface MEGAOpenMessageHeaderView : JSQMessagesLoadEarlierHeaderView

@property (weak, nonatomic) IBOutlet UILabel *chattingWithLabel;
@property (weak, nonatomic) IBOutlet UILabel *conversationWithLabel;
@property (weak, nonatomic) IBOutlet UIImageView *conversationWithAvatar;

@property (weak, nonatomic) IBOutlet UILabel *onlineStatusLabel;
@property (weak, nonatomic) IBOutlet UIView *onlineStatusView;

@property (weak, nonatomic) IBOutlet UILabel *introductionLabel;
@property (weak, nonatomic) IBOutlet UILabel *confidentialityLabel;
@property (weak, nonatomic) IBOutlet UILabel *authenticityLabel;

@end
