import Foundation
import MEGADomain

public final class MockMobileDataUseCase: MobileDataUseCaseProtocol {
    private var _isEnabled = false
    
    public init(isEnabled: Bool = false) {
        _isEnabled = isEnabled
    }
    
    public func isMobileDataForPreviewingEnabled() -> Bool {
        _isEnabled
    }
    
    public func updateMobileDataForPreviewingEnabled(_ enabled: Bool) {
        _isEnabled = enabled
    }
}
