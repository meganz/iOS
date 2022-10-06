

// MARK: - Use case protocol -
public protocol ContactsUseCaseProtocol {
    var isAuthorizedToAccessPhoneContacts: Bool { get }
}

// MARK: - Use case implementation -
public struct ContactsUseCase<T: ContactsRepositoryProtocol>: ContactsUseCaseProtocol {
    private var repository: T
    
    public var isAuthorizedToAccessPhoneContacts: Bool {
        repository.isAuthorizedToAccessPhoneContacts
    }

    public init(repository: T) {
        self.repository = repository
    }
}
