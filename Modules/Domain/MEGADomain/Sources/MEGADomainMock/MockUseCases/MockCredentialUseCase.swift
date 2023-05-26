import MEGADomain

public struct MockCredentialUseCase: CredentialUseCaseProtocol {
    
    private let session: Bool
    private let passcodeEnabled: Bool
    
    public init(session: Bool = false, passcodeEnabled: Bool = false) {
        self.session = session
        self.passcodeEnabled = passcodeEnabled
    }
    
    public func hasSession() -> Bool {
        session
    }
    
    public func isPasscodeEnabled() -> Bool {
        passcodeEnabled
    }
}
