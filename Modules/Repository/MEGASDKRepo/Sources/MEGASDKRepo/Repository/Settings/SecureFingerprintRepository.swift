import MEGADomain

public final class SecureFingerprintRepository: SecureFingerprintRepositoryProtocol {
    
    public static var newRepo: SecureFingerprintRepository {
        let manager = SharedSecureFingerprintManager()
        return SecureFingerprintRepository(manager: manager)
    }
    
    private var manager: any SecureFingerprintManagerProtocol
    
    public init(manager: any SecureFingerprintManagerProtocol) {
        self.manager = manager
    }
    
    public var secureFingerprintVerification: Bool {
        get {
            manager.secureFingerprintVerification
        }
        set {
            manager.secureFingerprintVerification = newValue
        }
    }
    
    public func setSecureFingerprintFlag(_ flag: Bool) async {
        await manager.setSecureFingerprintFlag(flag)
    }
    
    public func toggleSecureFingerprintFlag() {
        manager.toggleSecureFingerprintFlag()
    }
    
    public func secureFingerprintStatus() -> String {
        manager.secureFingerprintStatus()
    }
}
