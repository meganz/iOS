#import "GroupChatDetailsViewTableViewCell.h"

#import "MEGA-Swift.h"

@interface GroupChatDetailsViewTableViewCell () <ChatNotificationControlCellProtocol>

@end

@implementation GroupChatDetailsViewTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self updateAppearance];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    [self setDefaultState];
}

- (void)setDefaultState {
    self.delegate = nil;
    [self.notificationsSwitch setOn:YES];
    self.leftImageView.hidden = NO;
    self.enableLabel.hidden = YES;
    self.userInteractionEnabled = YES;
    self.destructive = NO;
}

- (void)setDestructive:(BOOL)isDestructive {
    _destructive = isDestructive;
    _nameLabel.textColor = isDestructive ? [UIColor mnz_redForTraitCollection:(self.traitCollection)] : UIColor.mnz_label;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    UIColor *color = self.onlineStatusView.backgroundColor;
    [super setSelected:selected animated:animated];
    
    if (selected){
        self.onlineStatusView.backgroundColor = color;
    }
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated{
    UIColor *color = self.onlineStatusView.backgroundColor;
    [super setHighlighted:highlighted animated:animated];
    
    if (highlighted){
        self.onlineStatusView.backgroundColor = color;
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
        [self updateAppearance];
    }
}

#pragma mark - Private

- (void)updateAppearance {
    self.enableLabel.textColor = self.rightLabel.textColor = UIColor.mnz_secondaryLabel;
    self.emailLabel.textColor = [UIColor mnz_subtitlesForTraitCollection:self.traitCollection];
    self.nameLabel.textColor = self.isDestructive ? [UIColor mnz_redForTraitCollection:(self.traitCollection)] : UIColor.mnz_label;
}

- (IBAction)notificationSwitchValueChanged:(UISwitch *)sender {
    if ([self.delegate respondsToSelector:@selector(notificationSwitchValueChanged:)]) {
        [self.delegate notificationSwitchValueChanged:sender];
    }
}

#pragma mark - ChatNotificationControlCellProtocol

- (UIImageView *)iconImageView {
    return self.leftImageView;
}

@end
