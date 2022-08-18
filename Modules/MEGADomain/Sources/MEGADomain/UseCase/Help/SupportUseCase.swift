import Combine

public protocol SupportUseCaseProtocol {
    func createSupportTicket(withMessage message: String) -> Future<Void, CreateSupportTicketErrorEntity>
}

public struct SupportUseCase: SupportUseCaseProtocol {
    private let repo: SupportRepositoryProtocol
    
    public init(repo: SupportRepositoryProtocol) {
        self.repo = repo
    }
    
    public func createSupportTicket(withMessage message: String) -> Future<Void, CreateSupportTicketErrorEntity> {
        repo.createSupportTicket(withMessage: message)
    }
}
