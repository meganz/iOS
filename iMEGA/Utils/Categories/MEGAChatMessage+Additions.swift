import MEGAL10n

extension MEGAChatMessage {
    
    @objc(contactNameAtIndex:) func contactName(at index: UInt) -> String? {
        guard usersCount > 0 else {
            return nil
        }
        
        if let user = MEGAStore.shareInstance().fetchUser(withUserHandle: userHandle(at: index)),
            let nickname = user.nickname,
            !nickname.isEmpty {
            return nickname
        }
        
        return userName(at: index)
    }
    
    @objc func attributedTextStringForScheduledMeetingChange(userNameDidAction: String) {
        let text = Strings.Localizable.Meetings.Scheduled.ManagementMessages.updated(userNameDidAction)
        
        let meetingUpdatedAttributedString = NSMutableAttributedString(
            string: text,
            attributes: [
                NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .subheadline),
                NSAttributedString.Key.foregroundColor: UIColor.label
            ]
        )
        meetingUpdatedAttributedString.addAttributes(
            [NSAttributedString.Key.font: UIFont.preferredFont(style: .subheadline, weight: .medium)], range: (text as NSString).range(of: userNameDidAction))
        
        attributedText = meetingUpdatedAttributedString
    }
}
