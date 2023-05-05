import MEGADomain

final class ChatStateListener: NSObject, MEGAChatDelegate {
    private var continuation: CheckedContinuation<Void, Error>?
    
    let chatId: ChatIdEntity
    let connectionState: ChatConnectionStatus
    let chatSDK: MEGAChatSdk
    
    init(chatId: ChatIdEntity, connectionState: ChatConnectionStatus, chatSDK: MEGAChatSdk = .shared) {
        self.chatId = chatId
        self.connectionState = connectionState
        self.chatSDK = chatSDK
        super.init()
    }
    
    func addListener() {
        chatSDK.add(self, queueType: .globalBackground)
    }
    
    func removeListener() {
        chatSDK.remove(self)
    }
    
    func connectionStateReached() async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
        }
    }
    
    func onChatConnectionStateUpdate(_ api: MEGAChatSdk, chatId: UInt64, newState: Int32) {
        guard let newConnectionState = MEGAChatConnection(rawValue: Int(newState))?.toChatConnectionStatus() else {
            checkTaskIfCancelled()
            return
        }
        
        
        if chatId == self.chatId, newConnectionState == connectionState {
            continuation?.resume()
            return
        }
        
       checkTaskIfCancelled()
    }
    
    private func checkTaskIfCancelled() {
        if Task.isCancelled {
            continuation?.resume(throwing: CancellationError())
        }
    }
}
