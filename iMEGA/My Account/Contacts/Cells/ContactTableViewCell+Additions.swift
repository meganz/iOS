import MEGADesignToken
import MEGAL10n

extension ContactTableViewCell {
    @objc func updateAppearance() {
        backgroundColor = UIColor.mnz_background()
        if UIColor.isDesignTokenEnabled() {
            nameLabel.textColor = TokenColors.Text.primary
            shareLabel?.textColor = TokenColors.Text.secondary
            permissionsLabel?.textColor = TokenColors.Text.primary
            
            contactDetailsButton?.tintColor = TokenColors.Icon.secondary
            nameLabel.textColor = TokenColors.Text.primary
            shareLabel?.textColor = TokenColors.Text.secondary
            permissionsLabel?.textColor = TokenColors.Text.primary
            
            controlSwitch?.onTintColor = TokenColors.Support.success
        } else {
            nameLabel.textColor = UIColor.label
            shareLabel?.textColor = UIColor.mnz_subtitles(for: traitCollection)
            permissionsLabel?.textColor = UIColor.mnz_tertiaryGray(for: traitCollection)
            
            nameLabel.textColor = UIColor.label
            shareLabel?.textColor = UIColor.mnz_subtitles(for: traitCollection)
            permissionsLabel?.textColor = UIColor.mnz_tertiaryGray(for: traitCollection)
        }
    }
    
    @objc func updateNewViewAppearance() {
        if UIColor.isDesignTokenEnabled() {
            contactNewLabel.textColor = TokenColors.Text.success
            contactNewLabelView.backgroundColor = TokenColors.Notifications.notificationSuccess
        } else {
            contactNewLabel.textColor = UIColor.mnz_whiteFFFFFF()
            contactNewLabelView.backgroundColor = UIColor.mnz_turquoise(for: traitCollection)
        }
    }
    
    @objc func onlineStatusBackgroundColor(_ status: MEGAChatStatus) -> UIColor {
        switch status {
        case .online: UIColor.isDesignTokenEnabled() ? TokenColors.Indicator.green : UIColor.chatStatusOnline
        case .offline: UIColor.isDesignTokenEnabled() ? TokenColors.Icon.disabled : UIColor.chatStatusOffline
        case .away: UIColor.isDesignTokenEnabled() ? TokenColors.Indicator.yellow : UIColor.chatStatusAway
        case .busy: UIColor.isDesignTokenEnabled() ? TokenColors.Indicator.pink : UIColor.chatStatusBusy
        default: .clear
        }
    }
    
    @objc func configureCellForContactsModeChatStartConversation(_ option: ContactsStartConversation) {
        permissionsImageView.isHidden = true
        
        switch option {
        case .newGroupChat:
            nameLabel.text = Strings.Localizable.newGroupChat
            avatarImageView.image = UIColor.isDesignTokenEnabled() ? UIImage.groupChatToken : UIImage.createGroup
        case .newMeeting:
            nameLabel.text = Strings.Localizable.Meetings.Create.newMeeting
            avatarImageView.image = UIColor.isDesignTokenEnabled() ? UIImage.newMeetingToken : UIImage.newMeeting
        case .joinMeeting:
            nameLabel.text = Strings.Localizable.Meetings.Link.LoggedInUser.joinButtonText
            avatarImageView.image = UIColor.isDesignTokenEnabled() ? UIImage.joinMeetingToken : UIImage.joinMeeting
        @unknown default: break
        }
        
        shareLabel.isHidden = true
    }
    
    @objc func removePendingShareIconColor() -> UIColor {
        UIColor.isDesignTokenEnabled() ? TokenColors.Support.error : UIColor.mnz_red(for: traitCollection)
    }
    
    @objc func prepareAddContactsCell() {
        permissionsImageView.isHidden = true
        avatarImageView.image = UIColor.isDesignTokenEnabled() ? UIImage.inviteContactShare : UIImage.inviteToChat
        nameLabel.text = Strings.Localizable.addContactButton
        shareLabel.isHidden = true
    }
}
