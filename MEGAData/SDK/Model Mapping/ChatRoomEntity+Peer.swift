
extension ChatRoomEntity.Peer {
    init(chatRoom: MEGAChatRoom, index: UInt) {
        self.handle = chatRoom.peerHandle(at: index)
        self.privilege = ChatRoomEntity.Privilege(
            rawValue: chatRoom.peerPrivilege(byHandle: handle)
        ) ?? .unknown
    }
}
