public protocol SupportUseCaseProtocol {
    func createSupportTicket(withMessage message: String) async throws
}

public struct SupportUseCase: SupportUseCaseProtocol {
    private let repo: SupportRepositoryProtocol
    
    public init(repo: SupportRepositoryProtocol) {
        self.repo = repo
    }
    
    public func createSupportTicket(withMessage message: String) async throws {
        try await repo.createSupportTicket(withMessage: message)
    }
}
