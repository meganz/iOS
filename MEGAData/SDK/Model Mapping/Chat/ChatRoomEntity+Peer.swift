import MEGADomain

extension ChatRoomEntity.Peer {
    init(chatRoom: MEGAChatRoom, index: UInt) {
        let handle = chatRoom.peerHandle(at: index)
        let privilege = MEGAChatRoomPrivilege(rawValue: chatRoom.peerPrivilege(byHandle: handle))?.toOwnPrivilegeEntity() ?? .unknown
        self.init(handle: handle, privilege: privilege)
    }
}
