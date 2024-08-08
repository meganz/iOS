import CallKit
import MEGADomain
import MEGASwift

protocol CallControlling {
    func request(_ transaction: CXTransaction, completion: @escaping ((any Error)?) -> Void)
    func request(_ transaction: CXTransaction) async throws
    func requestTransaction(with actions: [CXAction], completion: @escaping ((any Error)?) -> Void)
    func requestTransaction(with actions: [CXAction]) async throws
    func requestTransaction(with action: CXAction, completion: @escaping ((any Error)?) -> Void)
    func requestTransaction(with action: CXAction) async throws
}

extension CXCallController: CallControlling {}

final class CallKitCallManager {
    static var shared = CallKitCallManager(
        callController: CXCallController(),
        uuidFactory: {
            UUID()
        },
        chatIdBase64Converter: { chatId in
            HandleConverter.chatIdHandleConverter(chatId)
        }
    )
    private let callController: any CallControlling
    private let uuidFactory: () -> UUID
    private let chatIdBase64Converter: (ChatIdEntity) -> String
    @Atomic private var callsDictionary = [UUID: CallActionSync]()
    init(
        callController: any CallControlling,
        uuidFactory: @escaping () -> UUID,
        chatIdBase64Converter: @escaping (ChatIdEntity) -> String
    ) {
        self.callController = callController
        self.uuidFactory = uuidFactory
        self.chatIdBase64Converter = chatIdBase64Converter
    }
}

extension CallKitCallManager: CallManagerProtocol {
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
                addCallActionSync(actionSync, withUUID: startCallUUID)
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
        guard let callUUID = callUUID(forChatRoom: chatRoom) else { return }
        
        if endForAll {
            var endCallSync = callsDictionary[callUUID]
            endCallSync?.endForAll = true
            $callsDictionary.mutate {
                $0[callUUID] = endCallSync
            }
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
        guard let callUUID = callUUID(forChatRoom: chatRoom) else { return }

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
    
    func callUUID(forChatRoom chatRoom: ChatRoomEntity) -> UUID? {
        callsDictionary.first(where: { $0.value.chatRoom == chatRoom })?.key
    }
    
    func call(forUUID uuid: UUID) -> CallActionSync? {
        return callsDictionary[uuid]
    }
    
    func removeCall(withUUID uuid: UUID) {
        $callsDictionary.mutate {
            $0.removeValue(forKey: uuid)
        }
    }
    
    func removeAllCalls() {
        $callsDictionary.mutate {
            $0.removeAll()
        }
    }
    
    func addIncomingCall(withUUID uuid: UUID, chatRoom: ChatRoomEntity) {
        addCall(withUUID: uuid, chatRoom: chatRoom)
    }
    
    func updateCall(withUUID uuid: UUID, muted: Bool) {
        $callsDictionary.mutate {
            $0[uuid]?.audioEnabled = !muted
        }
    }
    
    // MARK: - Private
    private func addCall(withUUID uuid: UUID, chatRoom: ChatRoomEntity, audioEnabled: Bool = true, videoEnabled: Bool = false, notRinging: Bool = false, isJoiningActiveCall: Bool = false) {
        $callsDictionary.mutate {
            $0[uuid] = CallActionSync(chatRoom: chatRoom, videoEnabled: videoEnabled, notRinging: notRinging, isJoiningActiveCall: isJoiningActiveCall)
        }
    }
    
    private func addCallActionSync(_ action: CallActionSync, withUUID uuid: UUID) {
        $callsDictionary.mutate {
            $0[uuid] = action
        }
    }
}
