import Foundation

public protocol SecureFingerprintManagerProtocol {
    var secureFingerprintVerification: Bool { get set }
    var onToggleSecureFingerprintFlag: (() -> Void)? { get set }
    
    /// Setting Secure Fingerprint flag
    /// - Parameter flag: A boolean status for secure fingerprint flag
    /// This method needs to be async, because the implementation has a mutex, lock under the hood.
    func setSecureFingerprintFlag(_ flag: Bool) async
    func toggleSecureFingerprintFlag()
    func secureFingerprintStatus() -> String
}
