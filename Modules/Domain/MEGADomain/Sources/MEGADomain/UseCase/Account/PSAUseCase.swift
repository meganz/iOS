public protocol PSAUseCaseProtocol: Sendable {
    func getPSA() async throws -> PSAEntity
    func markAsSeenForPSA(withIdentifier identifier: PSAIdentifier)
}

public struct PSAUseCase<T: PSARepositoryProtocol>: PSAUseCaseProtocol {
    private let repo: T
    
    public init(repo: T) {
        self.repo = repo
    }
    
    public func getPSA() async throws -> PSAEntity {
        try await repo.getPSA()
    }
    
    public func markAsSeenForPSA(withIdentifier identifier: PSAIdentifier) {
        repo.markAsSeenForPSA(withIdentifier: identifier)
    }
}
