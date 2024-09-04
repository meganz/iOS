import Foundation

public protocol SupportUseCaseProtocol: Sendable {
    func createSupportTicket(withMessage message: String) async throws
}

public struct SupportUseCase: SupportUseCaseProtocol {
    private let repo: any SupportRepositoryProtocol
    
    public init(repo: any SupportRepositoryProtocol) {
        self.repo = repo
    }
    
    public func createSupportTicket(withMessage message: String) async throws {
        try await repo.createSupportTicket(withMessage: message)
    }
}
