#import "GroupChatDetailsViewTableViewCell.h"
#import "MEGA-Swift.h"

@interface GroupChatDetailsViewTableViewCell () <ChatNotificationControlCellProtocol>

@end

@implementation GroupChatDetailsViewTableViewCell

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    UIColor *color = self.onlineStatusView.backgroundColor;
    [super setSelected:selected animated:animated];
    
    if (selected){
        self.onlineStatusView.backgroundColor = color;
    }
}

-(void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated{
    UIColor *color = self.onlineStatusView.backgroundColor;
    [super setHighlighted:highlighted animated:animated];
    
    if (highlighted){
        self.onlineStatusView.backgroundColor = color;
    }
}

- (IBAction)notificationSwitchValueChanged:(UISwitch *)sender {
    if ([self.delegate respondsToSelector:@selector(notificationSwitchValueChanged:)]) {
        [self.delegate notificationSwitchValueChanged:sender];
    }
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.delegate = nil;
    [self.notificationsSwitch setOn:YES];
}

#pragma mark - ChatNotificationControlCellProtocol

- (UIImageView *)iconImageView {
    return self.leftImageView;
}

@end
