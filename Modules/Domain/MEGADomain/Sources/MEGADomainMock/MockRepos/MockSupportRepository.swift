import MEGADomain

public final class MockSupportRepository: SupportRepositoryProtocol {
    
    public var messages = [Message]()
    
    public enum Message: Equatable {
        case createSupportTicket(message: String)
    }
    
    public init() {}
    
    public func createSupportTicket(withMessage message: String) async throws {
        messages.append(.createSupportTicket(message: message))
    }
    
    public static var newRepo: MockSupportRepository {
        MockSupportRepository()
    }
}
