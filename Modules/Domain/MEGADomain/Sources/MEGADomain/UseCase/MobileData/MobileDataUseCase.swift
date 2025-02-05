import Foundation

public protocol MobileDataUseCaseProtocol {
    func isMobileDataForPreviewingEnabled() -> Bool
    func updateMobileDataForPreviewingEnabled(_ isEnabled: Bool)
}

public struct MobileDataUseCase: MobileDataUseCaseProtocol {
    @PreferenceWrapper(key: .useMobileDataForPreviewingOriginalPhoto, defaultValue: false)
    private var mobileDataForPreviewingEnabled: Bool
    
    public init(preferenceUseCase: some PreferenceUseCaseProtocol) {
        $mobileDataForPreviewingEnabled.useCase = preferenceUseCase
    }
    
    public func isMobileDataForPreviewingEnabled() -> Bool {
        mobileDataForPreviewingEnabled
    }
    
    public func updateMobileDataForPreviewingEnabled(_ isEnabled: Bool) {
        mobileDataForPreviewingEnabled = isEnabled
    }
}
