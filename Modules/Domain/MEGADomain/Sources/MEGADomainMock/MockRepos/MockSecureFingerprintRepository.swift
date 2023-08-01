import Foundation
import MEGADomain

public final class MockSecureFingerprintRepository: NSObject, SecureFingerprintRepositoryProtocol {
    
    public static var newRepo: MockSecureFingerprintRepository {
        MockSecureFingerprintRepository()
    }
    
    public var secureFingerprintVerification: Bool = false
    
    public enum Message: Equatable {
        case setSecureFingerprintFlag(Bool)
        case toggleSecureFingerprintFlag
        case secureFingerprintStatus
    }
    
    public var messages = [Message]()
    
    public func setSecureFingerprintFlag(_ flag: Bool) async {
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
