import MEGADomain

/// Defines a set of specific options from MEGA call system that CallKit does not provide when performing actions
/// It is used to synchronize the options of the call in MEGA call system with the call reported by CallKit
/// Flow: CallManagerProtocol triggers a call action and persist a CallActionSync. Provider (CallKit) will execute the action in the system and calls the provider delegate interface that will let know MEGA through CallsCoordinatorProtocol about next step, by sending CallActionSync object for that call action.
struct CallActionSync: Sendable {
    let chatRoom: ChatRoomEntity
    var audioEnabled: Bool = true
    var speakerEnabled: Bool = false
    var videoEnabled: Bool = false
    var notRinging: Bool = false
    var endForAll: Bool = false
    var isJoiningActiveCall: Bool = false
}

extension CallActionSync {
    static func startCallNoRinging(in chatRoom: ChatRoomEntity) -> Self {
        CallActionSync(chatRoom: chatRoom, notRinging: true)
    }
}
