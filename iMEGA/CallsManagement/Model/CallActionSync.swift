import MEGADomain

/// Represents a synchronized call action between the MEGA call system and external call controllers (e.g., CallKit or MEGA-specific controllers).
///
/// This struct ensures that specific call options from the MEGA system (such as `endForAll`) are retained and accurately reflected during the workflow involving external call controllers. It bridges the gap between the MEGA system's call state and the actions handled by the `CallControllerProtocol` implementation.
///
/// ### Workflow:
/// 1. A `CallControllerProtocol` implementation (e.g., CallKit) triggers a call action.
/// 2. The action is stored as a `CallActionSync` instance in `CallsManagerProtocol`.
/// 3. The call controller processes the action (e.g., system-level handling).
/// 4. The controller notifies the `CallsCoordinatorProtocol` of the completed action, which executes the corresponding behaviour in the MEGA system.
///
/// ### Properties:
/// - `chatRoom`: The chat room where the call is associated.
/// - `audioEnabled`: Indicates whether audio is enabled for the call (default is `true`).
/// - `speakerEnabled`: Indicates whether the speaker is enabled for the call (default is `false`).
/// - `videoEnabled`: Indicates whether video is enabled for the call (default is `false`).
/// - `notRinging`: Specifies whether the call should not play a ringing tone (default is `false`).
/// - `endForAll`: Indicates whether the call should end for all participants (default is `false`).
/// - `isJoiningActiveCall`: Determines whether the user is joining an already active call (default is `false`).
///
/// This struct is designed to ensure consistency in call state and actions, even when external systems, such as CallKit, are involved.
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
