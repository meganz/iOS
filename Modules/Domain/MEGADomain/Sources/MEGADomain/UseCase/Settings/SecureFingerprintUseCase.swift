public protocol SecureFingerprintUseCaseProtocol {
    var secureFingerprintVerification: Bool { get set }
    
    func setSecureFingerprintFlag(_ flag: Bool) async
    func toggleSecureFingerprintFlag()
    func secureFingerprintStatus() -> String
}

public struct SecureFingerprintUseCase<T: SecureFingerprintRepositoryProtocol>: SecureFingerprintUseCaseProtocol {
    
    private var repo: T
    
    public init(repo: T) {
        self.repo = repo
    }
    
    public var secureFingerprintVerification: Bool {
        get {
            repo.secureFingerprintVerification
        }
        set {
            repo.secureFingerprintVerification = newValue
        }
    }
    
    public func setSecureFingerprintFlag(_ flag: Bool) async {
        await repo.setSecureFingerprintFlag(flag)
    }
    
    public func toggleSecureFingerprintFlag() {
        repo.toggleSecureFingerprintFlag()
    }
    
    public func secureFingerprintStatus() -> String {
        repo.secureFingerprintStatus()
    }
}
