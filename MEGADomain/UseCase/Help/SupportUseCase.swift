import Combine

protocol SupportUseCaseProtocol {
    func createSupportTicket(withMessage message: String) -> Future<Void, CreateSupportTicketErrorEntity>
}

struct SupportUseCase: SupportUseCaseProtocol {
    private let repo: SupportRepositoryProtocol
    
    init(repo: SupportRepositoryProtocol) {
        self.repo = repo
    }
    
    func createSupportTicket(withMessage message: String) -> Future<Void, CreateSupportTicketErrorEntity> {
        repo.createSupportTicket(withMessage: message)
    }
}
