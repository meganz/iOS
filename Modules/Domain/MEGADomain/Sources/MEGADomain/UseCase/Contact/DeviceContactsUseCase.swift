// MARK: - Use case protocol -
public protocol DeviceContactsUseCaseProtocol {
    var isAuthorizedToAccessPhoneContacts: Bool { get }
}

// MARK: - Use case implementation -
public struct DeviceContactsUseCase<T: DeviceContactsRepositoryProtocol>: DeviceContactsUseCaseProtocol {
    private var repository: T
    
    public var isAuthorizedToAccessPhoneContacts: Bool {
        repository.isAuthorizedToAccessPhoneContacts
    }

    public init(repository: T) {
        self.repository = repository
    }
}
