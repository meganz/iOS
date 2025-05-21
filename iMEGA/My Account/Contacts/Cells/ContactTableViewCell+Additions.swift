import MEGAAssets
import MEGADesignToken
import MEGAL10n

extension ContactTableViewCell {
    @objc func setupColors() {
        backgroundColor = TokenColors.Background.page
        nameLabel.textColor = TokenColors.Text.primary
        shareLabel?.textColor = TokenColors.Text.secondary
        permissionsLabel?.textColor = TokenColors.Text.primary
        
        contactDetailsButton?.tintColor = TokenColors.Icon.secondary
        nameLabel.textColor = TokenColors.Text.primary
        shareLabel?.textColor = TokenColors.Text.secondary
        permissionsLabel?.textColor = TokenColors.Text.primary
        
        controlSwitch?.onTintColor = TokenColors.Support.success
    }
    
    @objc func updateNewViewAppearance() {
        contactNewLabel.textColor = TokenColors.Text.success
        contactNewLabelView.backgroundColor = TokenColors.Notifications.notificationSuccess
    }
    
    @objc func onlineStatusBackgroundColor(_ status: MEGAChatStatus) -> UIColor {
        switch status {
        case .online: TokenColors.Indicator.green
        case .offline: TokenColors.Icon.disabled
        case .away: TokenColors.Indicator.yellow
        case .busy: TokenColors.Indicator.pink
        default: .clear
        }
    }
    
    @objc func configureCellForContactsModeChatStartConversation(_ option: ContactsStartConversation) {
        permissionsImageView.isHidden = true
        
        switch option {
        case .newGroupChat:
            nameLabel.text = Strings.Localizable.newGroupChat
            avatarImageView.image = MEGAAssets.UIImage.groupChatToken
        case .newMeeting:
            nameLabel.text = Strings.Localizable.Meetings.Create.newMeeting
            avatarImageView.image =  MEGAAssets.UIImage.newMeetingToken
        case .joinMeeting:
            nameLabel.text = Strings.Localizable.Meetings.Link.LoggedInUser.joinButtonText
            avatarImageView.image = MEGAAssets.UIImage.joinMeetingToken
        @unknown default: break
        }
        
        shareLabel.isHidden = true
    }
    
    @objc func removePendingShareIconColor() -> UIColor {
        TokenColors.Support.error
    }
    
    @objc func prepareAddContactsCell() {
        permissionsImageView.isHidden = true
        avatarImageView.image = MEGAAssets.UIImage.inviteContactShare
        nameLabel.text = Strings.Localizable.addContactButton
        shareLabel.isHidden = true
    }
    
    @objc func configureNoteToSelfCell(_ noteToSelfChat: MEGAChatListItem) {
        nameLabel.text = noteToSelfChat.chatTitle()
        avatarImageView.image = noteToSelfChat.noteToSelfImage()
        avatarImageView.contentMode = .center
        shareLabel.isHidden = true
        verifiedImageView.isHidden = true
    }
}
