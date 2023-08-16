import MEGADomain
import MEGARepo
import MEGASdk
import UIKit

public final class SharedSecureFingerprintManager: SecureFingerprintManagerProtocol {
    
    @PreferenceWrapper(key: .secureFingerprintVerification, defaultValue: true, useCase: PreferenceUseCase.default)
    public var secureFingerprintVerification: Bool
    
    public var onToggleSecureFingerprintFlag: (() -> Void)?
    
    public init() {}
    
    public func setSecureFingerprintFlag(_ flag: Bool) async {
        MEGASdk.sharedSdk.setShareSecureFlag(flag)
    }
    
    public func toggleSecureFingerprintFlag() {
        let isSecure = !secureFingerprintVerification
        secureFingerprintVerification = isSecure
        Task {
            await setSecureFingerprintFlag(isSecure)
            onToggleSecureFingerprintFlag?()
        }
    }
    
    public func secureFingerprintStatus() -> String {
        secureFingerprintVerification ? "ENABLED" : "DISABLED"
    }
}

extension PreferenceUseCase where T == PreferenceRepository {
    static var `default`: PreferenceUseCase {
        PreferenceUseCase(repository: PreferenceRepository.newRepo)
    }
}
