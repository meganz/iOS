import Foundation
import MEGADomain

public extension ChatRoomEntity {
    /// Init method with default values (0, false, nil, [], ...)
    init(chatId: HandleEntity = .invalid,
         ownPrivilege: ChatRoomPrivilegeEntity = .unknown,
         changeType: ChangeType = .status,
         peerCount: UInt = 0,
         title: String? = "Unit tests",
         unreadCount: Int = 0,
         userTypingHandle: HandleEntity = .invalid,
         retentionTime: UInt = 0,
         creationTimeStamp: UInt64 = 0,
         previewersCount: UInt = 0,
         hasCustomTitle: Bool = false,
         isPublicChat: Bool = false,
         isPreview: Bool = false,
         isActive: Bool = false,
         isArchived: Bool = false,
         isMeeting: Bool = false,
         isNoteToSelf: Bool = false,
         chatType: ChatType = .oneToOne,
         peers: [ChatRoomEntity.Peer] = [],
         userHandle: HandleEntity = .invalid,
         isOpenInviteEnabled: Bool = false,
         isWaitingRoomEnabled: Bool = false,
         isTesting: Bool = true
    ) {
        self.init(
            chatId: chatId,
            ownPrivilege: ownPrivilege,
            changeType: changeType,
            peerCount: peerCount,
            authorizationToken: "",
            title: title,
            unreadCount: unreadCount,
            userTypingHandle: userTypingHandle,
            retentionTime: retentionTime,
            creationTimeStamp: creationTimeStamp,
            previewersCount: previewersCount,
            hasCustomTitle: hasCustomTitle,
            isPublicChat: isPublicChat,
            isPreview: isPreview,
            isActive: isActive,
            isArchived: isArchived,
            isMeeting: isMeeting,
            isNoteToSelf: isNoteToSelf,
            chatType: chatType,
            peers: peers,
            userHandle: userHandle,
            isOpenInviteEnabled: isOpenInviteEnabled,
            isWaitingRoomEnabled: isWaitingRoomEnabled
        )
    }
}
