import MEGAChatSdk
import MEGADomain

extension ChatRoomEntity.Peer {
    init(chatRoom: MEGAChatRoom, index: UInt) {
        let handle = chatRoom.peerHandle(at: index)
        let privilege = chatRoom.peerPrivilege(byHandle: handle).toChatRoomPrivilegeEntity()
        self.init(handle: handle, privilege: privilege)
    }
}
