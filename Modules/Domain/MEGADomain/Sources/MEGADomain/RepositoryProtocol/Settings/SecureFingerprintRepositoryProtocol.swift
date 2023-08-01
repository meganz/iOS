public protocol SecureFingerprintRepositoryProtocol: RepositoryProtocol {
    var secureFingerprintVerification: Bool { get set }
    
    func setSecureFingerprintFlag(_ flag: Bool) async
    func toggleSecureFingerprintFlag()
    func secureFingerprintStatus() -> String
}
