import Combine
@testable import MEGA
import MEGADomain

struct MockChatLinkUseCase: ChatLinkUseCaseProtocol {
    var link: String?
    var chatLinkUpdateSubject = PassthroughSubject<String?, Never>()
    var error: ChatRoomErrorEntity?
    
    func queryChatLink(for chatRoom: ChatRoomEntity) async throws -> String {
        if let error {
            throw error
        } else if let link {
            return link
        } else {
            throw ChatRoomErrorEntity.meetingLinkQueryError
        }
    }
    
    func createChatLink(for chatRoom: ChatRoomEntity) async throws -> String {
        if let error {
            throw error
        } else if let link {
            return link
        } else {
            throw ChatRoomErrorEntity.meetingLinkCreateError
        }
    }
    
    func removeChatLink(for chatRoom: ChatRoomEntity) async throws {
        if let error {
            throw error
        }
    }
    
    func queryChatLink(for chatRoom: ChatRoomEntity) {    }
    
    func createChatLink(for chatRoom: ChatRoomEntity) {    }
    
    func removeChatLink(for chatRoom: ChatRoomEntity) {    }
    
    mutating func monitorChatLinkUpdate(for chatRoom: ChatRoomEntity) -> AnyPublisher<String?, Never> {
        chatLinkUpdateSubject.eraseToAnyPublisher()
    }
}
