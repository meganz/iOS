import Foundation
import MEGAData

public final class MockSecureFingerprintManager: NSObject, SecureFingerprintManagerProtocol {
    public var onToggleSecureFingerprintFlag: (() -> Void)?
    
    public var secureFingerprintVerification: Bool = false
    
    public enum Message: Equatable {
        case setSecureFingerprintFlag(Bool)
        case toggleSecureFingerprintFlag
        case secureFingerprintStatus
    }
    
    public var messages = [Message]()
    
    public func setSecureFingerprintFlag(_ flag: Bool) {
        messages.append(.setSecureFingerprintFlag(flag))
    }
    
    public func toggleSecureFingerprintFlag() {
        messages.append(.toggleSecureFingerprintFlag)
    }
    
    public func secureFingerprintStatus() -> String {
        messages.append(.secureFingerprintStatus)
        return "ENABLED"
    }
}
