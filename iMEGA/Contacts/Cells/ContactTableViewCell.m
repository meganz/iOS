#import "ContactTableViewCell.h"
#import "MEGAPushNotificationSettings.h"
#import "MEGA-Swift.h"

@interface ContactTableViewCell () <ChatNotificationControlCellProtocol>
@end

@implementation ContactTableViewCell

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    
    BOOL editSingleRow = (self.subviews.count == 3); // leading or trailing UITableViewCellEditControl doesn't appear
    
    if (editing) {
        if (!editSingleRow) {
            [UIView animateWithDuration:0.3 animations:^{
                self.separatorInset = UIEdgeInsetsMake(0, 100, 0, 0);
                [self layoutIfNeeded];
            }];
        }
    } else {
        [UIView animateWithDuration:0.3 animations:^{
            self.separatorInset = UIEdgeInsetsMake(0, 60, 0, 0);
            [self layoutIfNeeded];
        }];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    UIColor *color = self.onlineStatusView.backgroundColor;
    [super setSelected:selected animated:animated];
    
    if (selected){
        self.onlineStatusView.backgroundColor = color;
    }
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
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
    return self.avatarImageView;
}

@end
