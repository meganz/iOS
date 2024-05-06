import MEGADomain

public struct MockContactsUseCase: ContactsUseCaseProtocol {
    private let contact: UserEntity?
    
    public init(contact: UserEntity? = nil) {
        self.contact = contact
    }
    
    public func contact(forUserHandle handle: HandleEntity) -> UserEntity? {
        contact
    }
    
    public var isContactVerificationWarningEnabled: Bool { false }
}
