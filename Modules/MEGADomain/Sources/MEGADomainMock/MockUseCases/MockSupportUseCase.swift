import Combine
import MEGADomain

public struct MockSupportUseCase: SupportUseCaseProtocol {
    
    var createSupportTicket = Future<Void, CreateSupportTicketErrorEntity> { promise in
        promise(.failure(.generic))
    }
    
    public init(createSupportTicket: Future<Void, CreateSupportTicketErrorEntity> = Future<Void, CreateSupportTicketErrorEntity> { promise in
        promise(.failure(.generic))
    }) {
        self.createSupportTicket = createSupportTicket
    }

    public func createSupportTicket(withMessage message: String) -> Future<Void, CreateSupportTicketErrorEntity> {
        createSupportTicket
    }
}
