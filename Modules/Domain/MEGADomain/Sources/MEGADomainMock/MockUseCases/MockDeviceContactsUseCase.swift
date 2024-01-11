import MEGADomain

public struct MockDeviceContactsUseCase: DeviceContactsUseCaseProtocol {
    public var authorized: Bool
    
    public var isAuthorizedToAccessPhoneContacts: Bool {
        authorized
    }
    
    public init(authorized: Bool = true) {
        self.authorized = authorized
    }
}
