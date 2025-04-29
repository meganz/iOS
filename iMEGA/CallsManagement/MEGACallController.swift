import MEGADomain

final class MEGACallController: CallControllerProtocol {
    static var shared = MEGACallController(
        uuidFactory: {
            UUID()
        },
        chatIdBase64Converter: { chatId in
            HandleConverter.chatIdHandleConverter(chatId)
        },
        callsManager: CallsManager.shared
    )
    
    private weak var callsCoordinator: (any CallsCoordinatorProtocol)?
    private let uuidFactory: () -> UUID
    private let chatIdBase64Converter: (ChatIdEntity) -> String
    private let callsManager: any CallsManagerProtocol
    
    init(
        uuidFactory: @escaping () -> UUID,
        chatIdBase64Converter: @escaping (ChatIdEntity) -> String,
        callsManager: some CallsManagerProtocol
    ) {
        self.uuidFactory = uuidFactory
        self.chatIdBase64Converter = chatIdBase64Converter
        self.callsManager = callsManager
    }
    
    func configureCallsCoordinator(_ callsCoordinator: CallsCoordinator) {
        self.callsCoordinator = callsCoordinator
        callsCoordinator.configureWebRTCAudioSession()
    }

    func startCall(with actionSync: CallActionSync) {
        guard let callsCoordinator else { return }
        let startCallUUID = uuidFactory()
        MEGALogDebug("[MEGACallController]: Call started")
        callsManager.addCall(actionSync, withUUID: startCallUUID)
        Task { @MainActor in
            await callsCoordinator.startCall(actionSync)
        }
    }
    
    func answerCall(in chatRoom: ChatRoomEntity, withUUID uuid: UUID) {
        guard let callsCoordinator else { return }
        MEGALogDebug("[MEGACallController]: Call answered")
        let uuidForAnswerCall = uuidFactory()
        callsManager.addCall(CallActionSync(chatRoom: chatRoom, audioEnabled: true), withUUID: uuidForAnswerCall)
        guard let callActionSync = callsManager.call(forUUID: uuidForAnswerCall) else { return }
        Task { @MainActor in
            await callsCoordinator.answerCall(callActionSync)
        }
    }
    
    func endCall(in chatRoom: ChatRoomEntity, endForAll: Bool) {
        guard let callsCoordinator else { return }
        MEGALogDebug("[MEGACallController]: End call")
        guard let callUUID = callsManager.callUUID(forChatRoom: chatRoom) else {
            MEGALogError("no callUUID for chatRoom \(chatRoom.chatId), expected a value")
            return
        }
        
        if endForAll {
            callsManager.updateEndForAllCall(withUUID: callUUID)
        }
        
        guard let callActionSync = callsManager.call(forUUID: callUUID) else {
            return
        }
        
        Task { @MainActor in
            await callsCoordinator.endCall(callActionSync)
        }
    }
    
    func muteCall(in chatRoom: ChatRoomEntity, muted: Bool) {
        guard let callsCoordinator else { return }
        MEGALogDebug("[MEGACallController]: Mute call")
        guard let callUUID = callsManager.callUUID(forChatRoom: chatRoom),
              let callActionSync = callsManager.call(forUUID: callUUID) else {
            return
        }
        
        Task { @MainActor in
            await callsCoordinator.muteCall(callActionSync)
        }
    }
}
