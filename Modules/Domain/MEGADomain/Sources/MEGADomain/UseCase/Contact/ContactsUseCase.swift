// MARK: - Use case protocol
public protocol ContactsUseCaseProtocol {
    func contact(forUserHandle handle: HandleEntity) -> UserEntity?
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
}
