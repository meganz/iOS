import MEGADomain

public struct MockContactsUseCase: ContactsUseCaseProtocol {
    public var authorized: Bool
    
    public var isAuthorizedToAccessPhoneContacts: Bool {
        authorized
    }
    
    public init(authorized: Bool = true) {
        self.authorized = authorized
    }
}
