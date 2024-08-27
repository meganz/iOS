import Combine

public protocol ChatLinkUseCaseProtocol: Sendable {
    func queryChatLink(for chatRoom: ChatRoomEntity) async throws -> String
    func createChatLink(for chatRoom: ChatRoomEntity) async throws -> String
    func removeChatLink(for chatRoom: ChatRoomEntity) async throws
    func queryChatLink(for chatRoom: ChatRoomEntity)
    func createChatLink(for chatRoom: ChatRoomEntity)
    func removeChatLink(for chatRoom: ChatRoomEntity)
    mutating func monitorChatLinkUpdate(for chatRoom: ChatRoomEntity) -> AnyPublisher<String?, Never>
}

public struct ChatLinkUseCase<T: ChatLinkRepositoryProtocol>: ChatLinkUseCaseProtocol {
    private var chatLinkRepository: T
    
    public init(chatLinkRepository: T) {
        self.chatLinkRepository = chatLinkRepository
    }

    public func queryChatLink(for chatRoom: ChatRoomEntity) async throws -> String {
        try await chatLinkRepository.queryChatLink(for: chatRoom)
    }
    
    public func createChatLink(for chatRoom: ChatRoomEntity) async throws -> String {
        try await chatLinkRepository.createChatLink(for: chatRoom)
    }
    
    public func removeChatLink(for chatRoom: ChatRoomEntity) async throws {
        try await chatLinkRepository.removeChatLink(for: chatRoom)
    }
    
    public func queryChatLink(for chatRoom: ChatRoomEntity) {
        chatLinkRepository.queryChatLink(for: chatRoom)
    }
    
    public func createChatLink(for chatRoom: ChatRoomEntity) {
        chatLinkRepository.createChatLink(for: chatRoom)
    }
    
    public func removeChatLink(for chatRoom: ChatRoomEntity) {
        chatLinkRepository.removeChatLink(for: chatRoom)
    }
    
    mutating public func monitorChatLinkUpdate(for chatRoom: ChatRoomEntity) -> AnyPublisher<String?, Never> {
        chatLinkRepository.monitorChatLinkUpdate(for: chatRoom)
    }
}
