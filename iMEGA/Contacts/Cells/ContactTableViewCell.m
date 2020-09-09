#import "ContactTableViewCell.h"

#ifdef MNZ_SHARE_EXTENSION
#import "MEGAShare-Swift.h"
#else
#import "MEGA-Swift.h"
#endif

@interface ContactTableViewCell () <ChatNotificationControlCellProtocol>
@end

#import "UIImageView+MNZCategory.h"

#import "MEGASdkManager.h"
#import "MEGAUser+MNZCategory.h"
#import "NSString+MNZCategory.h"

@implementation ContactTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    if (@available(iOS 11.0, *)) {
        self.avatarImageView.accessibilityIgnoresInvertColors = YES;
    }
    
    [self updateAppearance];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.delegate = nil;
    [self.notificationsSwitch setOn:YES];
    
    self.avatarImageView.image = nil;
    [self updateAppearance];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            [self updateAppearance];
        }
    }
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

- (void)updateAppearance {
    self.shareLabel.textColor = [UIColor mnz_subtitlesForTraitCollection:self.traitCollection];
    
    self.permissionsLabel.textColor = [UIColor mnz_tertiaryGrayForTraitCollection:self.traitCollection];
}

- (NSString *)userNameForUser:(MEGAUser *)user {
    NSString *userName;
    if (user.handle == MEGASdkManager.sharedMEGASdk.myUser.handle) {
        userName = [userName stringByAppendingString:[NSString stringWithFormat:@" (%@)", AMLocalizedString(@"me", @"The title for my message in a chat. The message was sent from yourself.")]];
    } else {
        userName = user.mnz_displayName;
    }
    
    return userName;
}

- (void)configureDefaultCellForUser:(MEGAUser *)user newUser:(BOOL)newUser {
    [self.avatarImageView mnz_setImageForUserHandle:user.handle name:self.nameLabel.text];
    self.verifiedImageView.hidden = ![MEGASdkManager.sharedMEGASdk areCredentialsVerifiedOfUser:user];
    
    NSString *userName = [self userNameForUser:user];
    self.nameLabel.text = userName ? userName : user.email;
    
    MEGAChatStatus userStatus = [MEGASdkManager.sharedMEGAChatSdk userOnlineStatus:user.handle];
    self.shareLabel.text = [NSString chatStatusString:userStatus];
    self.onlineStatusView.backgroundColor = [UIColor mnz_colorForChatStatus:userStatus];
    if (userStatus < MEGAChatStatusOnline) {
        [MEGASdkManager.sharedMEGAChatSdk requestLastGreen:user.handle];
    }
    
    if (newUser) {
        self.contactNewView.hidden = NO;
        self.contactNewLabel.text = AMLocalizedString(@"New", @"Label shown inside an unseen notification").uppercaseString;
        self.contactNewLabel.textColor = UIColor.whiteColor;
        self.contactNewLabelView.backgroundColor = [UIColor mnz_turquoiseForTraitCollection:self.traitCollection];
    } else {
        self.contactNewView.hidden = YES;
    }
}

- (void)configureCellForContactsModeFolderSharedWith:(MEGAUser *)user indexPath:(NSIndexPath *)indexPath {
    [self.avatarImageView mnz_setImageForUserHandle:user.handle name:self.nameLabel.text];
    self.verifiedImageView.hidden = ![MEGASdkManager.sharedMEGASdk areCredentialsVerifiedOfUser:user];
    
    if (indexPath.section == 0) {
        if (indexPath.row == 0) {
            self.permissionsImageView.hidden = YES;
            self.avatarImageView.image = [UIImage imageNamed:@"inviteToChat"];
            self.nameLabel.text = AMLocalizedString(@"addContactButton", @"Button title to 'Add' the contact to your contacts list");
            self.shareLabel.hidden = YES;
        } else {
            NSString *userName = [self userNameForUser:user];
            if (userName) {
                self.nameLabel.text = userName;
                self.shareLabel.text = user.email;
            } else {
                self.nameLabel.text = user.email;
                self.shareLabel.hidden = YES;
            }
        }
    } else if (indexPath.section == 1) {
        self.shareLabel.hidden = YES;
        self.permissionsImageView.image = [UIImage imageNamed:@"delete"];
        self.permissionsImageView.tintColor = [UIColor mnz_redForTraitCollection:(self.traitCollection)];
    }
}

- (void)configureCellForContactsModeChatStartConversation:(NSIndexPath *)indexPath {
    self.permissionsImageView.hidden = YES;
    if (indexPath.row == 0) {
        self.nameLabel.text = AMLocalizedString(@"inviteContact", @"Text shown when the user tries to make a call and the receiver is not a contact");
        self.avatarImageView.image = [UIImage imageNamed:@"inviteToChat"];
    } else if (indexPath.row == 1) {
        self.nameLabel.text = AMLocalizedString(@"New Group Chat", @"Text button for init a group chat");
        self.avatarImageView.image = [UIImage imageNamed:@"createGroup"];
    } else {
        self.nameLabel.text = AMLocalizedString(@"New Chat Link", @"Text button for init a group chat with link.");
        self.avatarImageView.image = [UIImage imageNamed:@"chatLink"];
    }
    self.shareLabel.hidden = YES;
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
