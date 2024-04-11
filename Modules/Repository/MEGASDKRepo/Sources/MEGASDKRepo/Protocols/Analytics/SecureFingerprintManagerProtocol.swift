import Foundation

public protocol SecureFingerprintManagerProtocol {
    var secureFingerprintVerification: Bool { get set }
    var onToggleSecureFingerprintFlag: (() -> Void)? { get set }
    func secureFingerprintStatus() -> String
}
