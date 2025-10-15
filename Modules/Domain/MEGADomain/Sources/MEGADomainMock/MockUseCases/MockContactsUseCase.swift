import MEGADomain

public struct MockContactsUseCase: ContactsUseCaseProtocol {
    private let contact: MEGADomain.UserEntity?
    
    public init(contact: MEGADomain.UserEntity? = nil) {
        self.contact = contact
    }
    
    public func contact(forUserHandle handle: HandleEntity) -> MEGADomain.UserEntity? {
        contact
    }
    
    public var isContactVerificationWarningEnabled: Bool { false }
}
