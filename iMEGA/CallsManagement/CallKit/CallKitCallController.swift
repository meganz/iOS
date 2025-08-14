import CallKit
import MEGADomain
import MEGASwift

final class CallKitCallController {
    static var shared = CallKitCallController(
        callController: CXCallController(),
        uuidFactory: {
            UUID()
        },
        chatIdBase64Converter: { chatId in
            HandleConverter.chatIdHandleConverter(chatId)
        },
        callsManager: CallsManager.shared,
        callKitProviderDelegateFactory: CallKitProviderDelegateProvider()
    )
    
    private let callController: CXCallController
    private let uuidFactory: () -> UUID
    private let chatIdBase64Converter: (ChatIdEntity) -> String
    private let callsManager: any CallsManagerProtocol
    private let callKitProviderDelegateFactory: any CallKitProviderDelegateProviding

    init(
        callController: CXCallController,
        uuidFactory: @escaping () -> UUID,
        chatIdBase64Converter: @escaping (ChatIdEntity) -> String,
        callsManager: some CallsManagerProtocol,
        callKitProviderDelegateFactory: some CallKitProviderDelegateProviding
    ) {
        self.callController = callController
        self.uuidFactory = uuidFactory
        self.chatIdBase64Converter = chatIdBase64Converter
        self.callsManager = callsManager
        self.callKitProviderDelegateFactory = callKitProviderDelegateFactory
    }
}

extension CallKitCallController: CallControllerProtocol {
    func configureCallsCoordinator(_ callsCoordinator: CallsCoordinator) {
        callsCoordinator.setupProviderDelegate(
            callKitProviderDelegateFactory.build(
                callCoordinator: callsCoordinator,
                callsManager: callsManager
            )
        )
    }
    
    func startCall(with actionSync: CallActionSync) {
        let startCallUUID = uuidFactory()
        let callKitHandle = CXHandle(type: .generic, value: chatIdBase64Converter(actionSync.chatRoom.chatId))
        let startCallAction = CXStartCallAction(call: startCallUUID, handle: callKitHandle)
        startCallAction.isVideo = actionSync.videoEnabled
        startCallAction.contactIdentifier = actionSync.chatRoom.title

        let transaction = CXTransaction(action: startCallAction)
        callController.request(transaction) { [weak self] error in
            guard let self else { return }
            if error == nil {
                MEGALogDebug("[CallKit]: Controller Call started")
                callsManager.addCall(actionSync, withUUID: startCallUUID)
            } else {
                MEGALogError("[CallKit]: Controller error starting call: \(error!.localizedDescription)")
            }
        }
    }
    
    func answerCall(in hatRoom: ChatRoomEntity, withUUID uuid: UUID) {
        let answerCallAction = CXAnswerCallAction(call: uuid)
        let transaction = CXTransaction(action: answerCallAction)
        callController.request(transaction) { error in
            if error == nil {
                MEGALogDebug("[CallKit]: Controller Call answered")
            } else {
                MEGALogError("[CallKit]: Controller error answering call: \(error!.localizedDescription)")
            }
        }
    }
    
    func endCall(in chatRoom: ChatRoomEntity, endForAll: Bool) {
        guard let callUUID = callsManager.callUUID(forChatRoom: chatRoom) else {
            MEGALogError("no callUUID for chatRoom \(chatRoom.chatId), expected a value")
            return
        }
        
        if endForAll {
            callsManager.updateEndForAllCall(withUUID: callUUID)
        }
        
        let endCallAction = CXEndCallAction(call: callUUID)
        
        let transaction = CXTransaction(action: endCallAction)
        callController.request(transaction) { error in
            if error == nil {
                MEGALogDebug("[CallKit]: Controller End call")
            } else {
                MEGALogError("[CallKit]: Controller error ending call: \(error!.localizedDescription)")
            }
        }
    }
    
    func muteCall(in chatRoom: ChatRoomEntity, muted: Bool) {
        guard let callUUID = callsManager.callUUID(forChatRoom: chatRoom) else { return }

        let muteCallAction = CXSetMutedCallAction(call: callUUID, muted: muted)
        
        let transaction = CXTransaction(action: muteCallAction)
        callController.request(transaction) { error in
            if error == nil {
                MEGALogDebug("[CallKit]: Controller mute/unmute call")
            } else {
                MEGALogError("[CallKit]: Controller error mute/unmute call: \(error!.localizedDescription)")
            }
        }
    }
}
