@preconcurrency import Combine
import MEGAChatSdk
import MEGADomain
import MEGASwift

public struct ChatLinkRepository: ChatLinkRepositoryProtocol {
    public static var newRepo: ChatLinkRepository {
        ChatLinkRepository(sdk: MEGAChatSdk.sharedChatSdk)
    }
    
    private let sdk: MEGAChatSdk
    private var chatLinkUpdateListener: ChatRequestListener?
    
    typealias ChatLinkOperation = (_ chatId: UInt64, _ delegate: ChatRequestDelegate) -> Void
    
    public func queryChatLink(for chatRoom: ChatRoomEntity) async throws -> String {
        try await performChatLinkOperation(sdk.queryChatLink, for: chatRoom.chatId)
    }
    
    public func createChatLink(for chatRoom: ChatRoomEntity) async throws -> String {
        try await performChatLinkOperation(sdk.createChatLink, for: chatRoom.chatId)
    }
    
    public func removeChatLink(for chatRoom: ChatRoomEntity) async throws {
        try await withAsyncThrowingValue { completion in
            sdk.removeChatLink(chatRoom.chatId, delegate: ChatRequestDelegate { result in
                switch result {
                case .success:
                    completion(.success(()))
                case .failure:
                    completion(.failure(ChatRoomErrorEntity.meetingLinkRemoveError))
                }
            })
        }
    }
    
    public func queryChatLink(for chatRoom: ChatRoomEntity) {
        sdk.queryChatLink(chatRoom.chatId)
    }
    
    public func createChatLink(for chatRoom: ChatRoomEntity) {
        sdk.createChatLink(chatRoom.chatId)
    }
    
    public func removeChatLink(for chatRoom: ChatRoomEntity) {
        sdk.removeChatLink(chatRoom.chatId)
    }
    
    public mutating func monitorChatLinkUpdate(for chatRoom: ChatRoomEntity) -> AnyPublisher<String?, Never> {
        let chatLinkUpdateListener = ChatRequestListener(sdk: sdk, chatId: chatRoom.chatId, changeType: .chatLinkHandle)
        self.chatLinkUpdateListener = chatLinkUpdateListener
        return chatLinkUpdateListener
            .monitor
            .eraseToAnyPublisher()
    }
    
    private func performChatLinkOperation(_ operation: ChatLinkOperation, for chatRoomId: UInt64) async throws -> String {
        try await withAsyncThrowingValue { completion in
            operation(chatRoomId, ChatRequestDelegate { result in
                switch result {
                case .success(let request):
                    if let text = request.text {
                        completion(.success(text))
                    } else {
                        completion(.failure(ChatRoomErrorEntity.emptyTextResponse))
                    }
                case .failure:
                    completion(.failure(ChatRoomErrorEntity.meetingLinkCreateError))
                }
            })
        }
    }
}

private final class ChatRequestListener: NSObject, MEGAChatRequestDelegate, Sendable {
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
