@preconcurrency import Combine
import MEGADomain

public struct MockChatLinkUseCase: ChatLinkUseCaseProtocol {
    private let link: String?
    private let chatLinkUpdateSubject = PassthroughSubject<String?, Never>()
    private let error: ChatRoomErrorEntity?
    
    public init(
        link: String? = nil,
        error: ChatRoomErrorEntity? = nil
    ) {
        self.link = link
        self.error = error
    }
    
    public func queryChatLink(for chatRoom: ChatRoomEntity) async throws -> String {
        if let error {
            throw error
        } else if let link {
            return link
        } else {
            throw ChatRoomErrorEntity.meetingLinkQueryError
        }
    }
    
    public func createChatLink(for chatRoom: ChatRoomEntity) async throws -> String {
        if let error {
            throw error
        } else if let link {
            return link
        } else {
            throw ChatRoomErrorEntity.meetingLinkCreateError
        }
    }
    
    public func removeChatLink(for chatRoom: ChatRoomEntity) async throws {
        if let error {
            throw error
        }
    }
    
    public func queryChatLink(for chatRoom: ChatRoomEntity) {
        chatLinkUpdateSubject.send(link)
    }
    
    public func createChatLink(for chatRoom: ChatRoomEntity) {
        chatLinkUpdateSubject.send("New chat or meeting link")
    }
    
    public func removeChatLink(for chatRoom: ChatRoomEntity) {
        chatLinkUpdateSubject.send(nil)
    }
    
    public mutating func monitorChatLinkUpdate(for chatRoom: ChatRoomEntity) -> AnyPublisher<String?, Never> {
        chatLinkUpdateSubject.eraseToAnyPublisher()
    }
}
