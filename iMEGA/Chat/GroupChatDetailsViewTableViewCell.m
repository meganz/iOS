#import "GroupChatDetailsViewTableViewCell.h"

#import "MEGA-Swift.h"

@interface GroupChatDetailsViewTableViewCell () <ChatNotificationControlCellProtocol>

@end

@implementation GroupChatDetailsViewTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self updateAppearance];
    [self configureImages];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    [self setDefaultState];
}

- (void)setDefaultState {
    self.delegate = nil;
    [self.controlSwitch setOn:YES];
    self.leftImageView.hidden = NO;
    self.enableLabel.hidden = YES;
    self.userInteractionEnabled = YES;
    self.destructive = NO;
}

- (void)setDestructive:(BOOL)isDestructive {
    _destructive = isDestructive;
    [self configNameLabelColorWithIsDestructive:isDestructive];
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

- (void)configureImages {
    self.verifiedImageView.image = [UIImage megaImageWithNamed:@"contactVerified"];
}

- (IBAction)notificationSwitchValueChanged:(UISwitch *)sender {
    if ([self.delegate respondsToSelector:@selector(controlSwitchValueChanged:fromCell:)]) {
        [self.delegate controlSwitchValueChanged:sender fromCell:self];
    }
}

#pragma mark - ChatNotificationControlCellProtocol

- (UIImageView *)iconImageView {
    return self.leftImageView;
}

@end
