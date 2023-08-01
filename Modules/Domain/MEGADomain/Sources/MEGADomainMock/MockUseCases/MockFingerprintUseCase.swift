import MEGADomain

public final class MockFingerprintUseCase: SecureFingerprintUseCaseProtocol {
    private(set) var setSecureFingerprintFlagCallCount = 0
    private(set) var toggleSecureFingerprintFlagCallCount = 0
    
    public var secureFingerprintVerification: Bool = false
    
    public init() {}
    
    public func setSecureFingerprintFlag(_ flag: Bool) async {
        setSecureFingerprintFlagCallCount += 1
    }
    
    public func toggleSecureFingerprintFlag() {
        toggleSecureFingerprintFlagCallCount += 1
    }
    
    public func secureFingerprintStatus() -> String {
        return "ENABLED"
    }
}
