import MEGADomain

public struct MockSupportRepository: SupportRepositoryProtocol {
    public actor State {
        public var messages = [Message]()
        
        func insertMessage(_ message: Message) {
            messages.append(message)
        }
    }
    public enum Message: Equatable, Sendable {
        case createSupportTicket(message: String)
    }
    
    public let state = State()
    
    public init() {}
    
    public func createSupportTicket(withMessage message: String) async throws {
        await state.insertMessage(.createSupportTicket(message: message))
    }
    
    public static var newRepo: MockSupportRepository {
        MockSupportRepository()
    }
}
