// MARK: - Use case protocol
public protocol ContactsUseCaseProtocol: Sendable {
    func contact(forUserHandle handle: HandleEntity) -> UserEntity?
    var isContactVerificationWarningEnabled: Bool { get }
}

// MARK: - Use case implementation
public struct ContactsUseCase<T: ContactsRepositoryProtocol>: ContactsUseCaseProtocol {
    private var repository: T
    
    public init(repository: T) {
        self.repository = repository
    }
    
    public func contact(forUserHandle handle: HandleEntity) -> UserEntity? {
        repository.contact(forUserHandle: handle)
    }
    
    public var isContactVerificationWarningEnabled: Bool {
        repository.isContactVerificationWarningEnabled
    }
}
