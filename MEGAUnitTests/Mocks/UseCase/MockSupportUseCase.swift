import Combine
@testable import MEGA

struct MockSupportUseCase: SupportUseCaseProtocol {
    var createSupportTicket = Future<Void, CreateSupportTicketErrorEntity> { promise in
        promise(.failure(.generic))
    }
    
    func createSupportTicket(withMessage message: String) -> Future<Void, CreateSupportTicketErrorEntity> {
        createSupportTicket
    }
}
