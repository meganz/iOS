#import "ContactTableViewCell.h"

@import MEGAL10nObjc;

#ifdef MNZ_SHARE_EXTENSION
#import "MEGAShare-Swift.h"
#else
#import "MEGA-Swift.h"
#endif

@interface ContactTableViewCell () <ChatNotificationControlCellProtocol>
@end

#import "UIImageView+MNZCategory.h"

#import "MEGAUser+MNZCategory.h"
#import "NSString+MNZCategory.h"
@import MEGASDKRepo;

@implementation ContactTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.avatarImageView.accessibilityIgnoresInvertColors = YES;
    
    [self setupColors];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.delegate = nil;
    [self.controlSwitch setOn:YES];
    
    self.avatarImageView.image = nil;
    [self setupColors];
}

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

#pragma mark - Private

- (NSString *)userNameForUser:(MEGAUser *)user {
    NSString *userName;
    if (user.handle == MEGASdk.currentUserHandle.unsignedLongLongValue) {
        userName = [userName stringByAppendingString:[NSString stringWithFormat:@" (%@)", LocalizedString(@"me", @"The title for my message in a chat. The message was sent from yourself.")]];
    } else {
        userName = user.mnz_displayName;
    }
    
    return userName;
}

- (void)configureDefaultCellForUser:(MEGAUser *)user newUser:(BOOL)newUser {
    [self.avatarImageView mnz_setImageForUserHandle:user.handle name:self.nameLabel.text];
    self.verifiedImageView.hidden = ![MEGASdk.shared areCredentialsVerifiedOfUser:user];
    
    NSString *userName = [self userNameForUser:user];
    self.nameLabel.text = userName ? userName : user.email;
    
    MEGAChatStatus userStatus = [MEGAChatSdk.shared userOnlineStatus:user.handle];
    self.shareLabel.text = [NSString chatStatusString:userStatus];
    self.onlineStatusView.backgroundColor = [self onlineStatusBackgroundColor:userStatus];
    if (userStatus < MEGAChatStatusOnline) {
        [MEGAChatSdk.shared requestLastGreen:user.handle];
    }
    
    if (newUser) {
        self.contactNewView.hidden = NO;
        self.contactNewLabel.text = LocalizedString(@"New", @"Label shown inside an unseen notification");
        [self updateNewViewAppearance];
    } else {
        self.contactNewView.hidden = YES;
    }
}

- (void)configureCellForContactsModeFolderSharedWith:(MEGAUser *)user indexPath:(NSIndexPath *)indexPath {
    [self.avatarImageView mnz_setImageForUserHandle:user.handle name:self.nameLabel.text];
    self.verifiedImageView.hidden = ![MEGASdk.shared areCredentialsVerifiedOfUser:user];
    
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            [self prepareAddContactsCell];
        } else {
            NSString *userName = [self userNameForUser:user];
            if (userName) {
                self.nameLabel.text = userName;
                self.shareLabel.text = user.email;
                self.shareLabel.hidden = NO;
            } else {
                self.nameLabel.text = user.email;
                self.shareLabel.hidden = YES;
            }
        }
    } else if (indexPath.section == 1) {
        self.shareLabel.hidden = YES;
        self.permissionsImageView.hidden = NO;
        self.permissionsImageView.image = [UIImage imageNamed:@"delete"];
        self.permissionsImageView.tintColor = [self removePendingShareIconColor];
    }
}

- (IBAction)notificationSwitchValueChanged:(UISwitch *)sender {
    if ([self.delegate respondsToSelector:@selector(notificationSwitchValueChanged:)]) {
        [self.delegate notificationSwitchValueChanged:sender];
    }
}

#pragma mark - ChatNotificationControlCellProtocol

- (UIImageView *)iconImageView {
    return self.avatarImageView;
}

@end
