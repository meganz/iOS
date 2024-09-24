public protocol AppDistributionUseCaseProtocol: Sendable {
    func checkForUpdate() async throws -> AppDistributionReleaseEntity?
}

public struct AppDistributionUseCase<T: AppDistributionRepositoryProtocol>: AppDistributionUseCaseProtocol {
    
    private let repo: T
    
    public init(repo: T) {
        self.repo = repo
    }
    
    public func checkForUpdate() async throws -> AppDistributionReleaseEntity? {
        try? await repo.checkForUpdate()
    }
}
