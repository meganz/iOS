public protocol UserAttributeUseCaseProtocol {
    func updateUserAttribute(_ attribute: UserAttributeEntity, value: String) async throws
}

public struct UserAttributeUseCase<T: UserAttributeRepositoryProtocol>: UserAttributeUseCaseProtocol {
    private let repo: T
    
    public init(repo: T) {
        self.repo = repo
    }
    
    public func updateUserAttribute(_ attribute: UserAttributeEntity, value: String) async throws {
        try await repo.updateUserAttribute(attribute, value: value)
    }
}
