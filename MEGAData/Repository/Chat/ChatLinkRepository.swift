import MEGADomain
import Combine

struct ChatLinkRepository: ChatLinkRepositoryProtocol {
    static var newRepo = ChatLinkRepository(sdk: MEGASdkManager.sharedMEGAChatSdk())
    
    private let sdk: MEGAChatSdk
    private var chatLinkUpdateListener: ChatRequestListener?

    func queryChatLink(for chatRoom: ChatRoomEntity) async throws -> String {
        
        try await withCheckedThrowingContinuation { continuation in
            
            sdk.queryChatLink(chatRoom.chatId, delegate: MEGAChatResultRequestDelegate { result in
                switch result {
                case .success(let request):
                    continuation.resume(returning: request.text)
                case .failure:
                    continuation.resume(throwing: ChatRoomErrorEntity.meetingLinkQueryError)
                }
            })
        }
    }
    
    func createChatLink(for chatRoom: ChatRoomEntity) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            sdk.createChatLink(chatRoom.chatId, delegate: MEGAChatResultRequestDelegate { result in
                switch result {
                case .success(let request):
                    continuation.resume(returning: request.text)
                case .failure:
                    continuation.resume(throwing: ChatRoomErrorEntity.meetingLinkCreateError)
                }
            })
        }
    }
    
    func removeChatLink(for chatRoom: ChatRoomEntity) async throws {
        try await withCheckedThrowingContinuation { continuation in
            sdk.removeChatLink(chatRoom.chatId, delegate: MEGAChatResultRequestDelegate { result in
                switch result {
                case .success:
                    continuation.resume()
                case .failure:
                    continuation.resume(throwing: ChatRoomErrorEntity.meetingLinkRemoveError)
                }
            })
        }
    }
    
    func queryChatLink(for chatRoom: ChatRoomEntity) {
        sdk.queryChatLink(chatRoom.chatId)
    }
    
    func createChatLink(for chatRoom: ChatRoomEntity) {
        sdk.createChatLink(chatRoom.chatId)
    }
    
    func removeChatLink(for chatRoom: ChatRoomEntity) {
        sdk.removeChatLink(chatRoom.chatId)
    }
    
    mutating func monitorChatLinkUpdate(for chatRoom: ChatRoomEntity) -> AnyPublisher<String?, Never> {
        let chatLinkUpdateListener = ChatRequestListener(sdk: sdk, chatId: chatRoom.chatId, changeType: .chatLinkHandle)
        self.chatLinkUpdateListener = chatLinkUpdateListener
        return chatLinkUpdateListener
            .monitor
            .eraseToAnyPublisher()
    }
}

private final class ChatRequestListener: NSObject, MEGAChatRequestDelegate {
    private let sdk: MEGAChatSdk
    private let changeType: MEGAChatRequestType
    let chatId: HandleEntity

    private let source = PassthroughSubject<String?, Never>()

    var monitor: AnyPublisher<String?, Never> {
        source.eraseToAnyPublisher()
    }

    init(sdk: MEGAChatSdk, chatId: HandleEntity, changeType: MEGAChatRequestType) {
        self.sdk = sdk
        self.changeType = changeType
        self.chatId = chatId
        super.init()
        sdk.add(self)
    }

    deinit {
        sdk.remove(self)
    }

    func onChatRequestFinish(_ api: MEGAChatSdk, request: MEGAChatRequest, error: MEGAChatError) {
        if request.type == changeType,
           chatId == request.chatHandle {
            source.send(request.text)
        }
    }
}
