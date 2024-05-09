import MEGADomain

final class CallKitCallManager {
    static var shared = CallKitCallManager()

    private let callController = CXCallController()
    
    private var callsDictionary = [UUID: CallActionSync]()
}

extension CallKitCallManager: CallManagerProtocol {
    
    func startCall(in chatRoom: ChatRoomEntity, chatIdBase64Handle: String, hasVideo: Bool, notRinging: Bool) {
        let startCallUUID = UUID()
        let callKitHandle = CXHandle(type: .generic, value: chatIdBase64Handle)
        let startCallAction = CXStartCallAction(call: startCallUUID, handle: callKitHandle)
        startCallAction.isVideo = hasVideo
        startCallAction.contactIdentifier = chatRoom.title

        let transaction = CXTransaction(action: startCallAction)
        callController.request(transaction) { [weak self] error in
            if error == nil {
                MEGALogDebug("[CallKit]: Controller Call started")
                self?.callsDictionary[startCallUUID] = CallActionSync(chatRoom: chatRoom, videoEnabled: hasVideo, notRinging: notRinging)
            } else {
                MEGALogError("[CallKit]: Controller error starting call: \(error!.localizedDescription)")
            }
        }
    }
    
    func answerCall(in chatRoom: ChatRoomEntity) {
        let answerCallUUID = UUID()
        let answerCallAction = CXAnswerCallAction(call: answerCallUUID)
        let transaction = CXTransaction(action: answerCallAction)
        callController.request(transaction) { [weak self] error in
            if error == nil {
                MEGALogDebug("[CallKit]: Controller Call answered")
                self?.callsDictionary[answerCallUUID] = CallActionSync(chatRoom: chatRoom, audioEnabled: !chatRoom.isMeeting)
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
            callsDictionary[callUUID] = endCallSync
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
        callsDictionary.removeValue(forKey: uuid)
    }
    
    func removeAllCalls() {
        callsDictionary.removeAll()
    }
    
    func addCall(withUUID uuid: UUID, chatRoom: ChatRoomEntity) {
        callsDictionary[uuid] = CallActionSync(chatRoom: chatRoom)
    }
    
    func updateCall(withUUID uuid: UUID, muted: Bool) {
        callsDictionary[uuid]?.audioEnabled = !muted
    }
}
