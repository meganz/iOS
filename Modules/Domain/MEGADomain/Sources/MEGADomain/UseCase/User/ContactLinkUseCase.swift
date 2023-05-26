public protocol ContactLinkUseCaseProtocol {
    func contactLinkQuery(handle: HandleEntity) async throws -> ContactLinkEntity?
}

public struct ContactLinkUseCase: ContactLinkUseCaseProtocol {
    private let repo: ContactLinkRepositoryProtocol
    
    public init(repo: ContactLinkRepositoryProtocol) {
        self.repo = repo
    }
    
    public func contactLinkQuery(handle: HandleEntity) async throws -> ContactLinkEntity? {
        try await repo.contactLinkQuery(handle: handle)
    }
}
