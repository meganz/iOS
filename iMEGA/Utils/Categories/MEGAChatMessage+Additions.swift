import MEGADesignToken
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
    
    @objc func alterParticipantsMessage(
        fullNameDidAction: String,
        fullNameReceiveAction: String,
        isMeeting: Bool
    ) {
        var message = ""
        let textFontRegular = UIFont.preferredFont(forTextStyle: .subheadline)
        let textFontMedium = UIFont.preferredFont(style: .subheadline, weight: .medium)
        let haveDidAction = !fullNameDidAction.isEmpty && fullNameDidAction != fullNameReceiveAction
        switch privilege {
        case -1:
            if haveDidAction {
                if isMeeting {
                    message = Strings.Localizable.Chat.Message.wasRemovedFromTheMeetingBy
                } else {
                    message = Strings.Localizable.wasRemovedFromTheGroupChatBy
                }
                message = message.replacingOccurrences(of: "[A]", with: fullNameReceiveAction)
                message = message.replacingOccurrences(of: "[B]", with: fullNameDidAction)
            } else {
                if isMeeting {
                    message = Strings.Localizable.Chat.Message.leftTheMeeting
                } else {
                    message = Strings.Localizable.leftTheGroupChat
                }
                message = message.replacingOccurrences(of: "[A]", with: fullNameReceiveAction)
            }
        case -2:
            if haveDidAction {
                if isMeeting {
                    message = Strings.Localizable.Chat.Message.joinedTheMeetingByInvitationFrom
                } else {
                    message = Strings.Localizable.joinedTheGroupChatByInvitationFrom
                }
                message = message.replacingOccurrences(of: "[A]", with: fullNameReceiveAction)
                message = message.replacingOccurrences(of: "[B]", with: fullNameDidAction)
            } else {
                if isMeeting {
                    message = Strings.Localizable.Chat.Message.joinedTheMeeting
                    message = message.replacingOccurrences(of: "[A]", with: fullNameReceiveAction)
                } else {
                    message = Strings.Localizable.joinedTheGroupChat(fullNameReceiveAction)
                }
            }
        default:
            return
        }
        let mutableAttributedString = NSMutableAttributedString(
            string: message,
            attributes: [
                .font: textFontRegular,
                .foregroundColor: UIColor.label
            ]
        )
        mutableAttributedString.addAttributes(
            [.font: textFontMedium],
            range: NSString(string: message).range(of: fullNameReceiveAction)
        )
        if haveDidAction {
            mutableAttributedString.addAttributes(
                [.font: textFontMedium],
                range: NSString(string: message).range(of: fullNameDidAction)
            )
        }
        attributedText = mutableAttributedString
    }
    
    @objc func normalTextColor(isFromCurrentSender: Bool) -> UIColor {
        isFromCurrentSender ? TokenColors.Text.inverse : TokenColors.Text.primary
    }
}
