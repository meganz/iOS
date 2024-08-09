public protocol ContactLinkUseCaseProtocol: Sendable {
    func contactLinkQuery(handle: HandleEntity) async throws -> ContactLinkEntity?
}

public struct ContactLinkUseCase: ContactLinkUseCaseProtocol {
    private let repo: any ContactLinkRepositoryProtocol
    
    public init(repo: any ContactLinkRepositoryProtocol) {
        self.repo = repo
    }
    
    public func contactLinkQuery(handle: HandleEntity) async throws -> ContactLinkEntity? {
        try await repo.contactLinkQuery(handle: handle)
    }
}
