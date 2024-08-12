import MEGADesignToken
import MEGAL10n

struct ChatRoomsTopRowViewState {
    let image: UIImage
    let description: String
    let rightDetail: String?
    let action: (() -> Void)
    
    init(image: UIImage, description: String, rightDetail: String? = nil, action: @escaping () -> Void) {
        self.image = image
        self.description = description
        self.rightDetail = rightDetail
        self.action = action
    }
}

extension ChatRoomsTopRowViewState {
    static func contactsOnMega(
        designTokenEnabled: Bool,
        action: @escaping () -> Void
    ) -> Self {
        ChatRoomsTopRowViewState(
            image: designTokenEnabled ? UIImage.inviteToChatDesignToken : UIImage.inviteToChat,
            description: Strings.Localizable.inviteContactNow,
            action: action
        )
    }
    
    static func archivedChatsViewState(
        count: UInt,
        action: @escaping () -> Void
    ) -> Self {
        ChatRoomsTopRowViewState(
            image: UIImage(resource: .archiveChat),
            description: Strings.Localizable.archivedChats,
            rightDetail: "\(count)",
            action: action
        )
    }
}
