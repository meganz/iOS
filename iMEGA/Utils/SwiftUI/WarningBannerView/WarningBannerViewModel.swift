import MEGAAnalyticsiOS
import MEGAAppPresentation

enum WarningBannerType: CustomStringConvertible, Equatable {
    case noInternetConnection
    case limitedPhotoAccess
    case contactsNotVerified
    case contactNotVerifiedSharedFolder(String)
    case backupStatusError(String)
    case fullStorageOverQuota
    case almostFullStorageOverQuota
    
    /// The `Severity` enum defines the levels of severity for warnings or alerts displayed in the app.
    ///
    /// This enum is used to categorise different warnings, which influences the different banners' style.
    /// The severity level determines how urgent or important a warning is, and different severity levels
    /// will result in different background colors and icon styles for the warning banners.
    enum Severity {
        case critical
        case warning
    }
}

@MainActor
@objc final class WarningBannerViewModel: NSObject, ObservableObject {
    let warningType: WarningBannerType
    let router: (any WarningBannerViewRouting)?
    let shouldShowCloseButton: Bool
    var closeButtonAction: (() -> Void)?
    var onHeightChange: ((CGFloat) -> Void)?
    private let tracker: any AnalyticsTracking
    
    let applyNewDesign: Bool
    
    init(warningType: WarningBannerType,
         router: (any WarningBannerViewRouting)? = nil,
         shouldShowCloseButton: Bool = false,
         closeButtonAction: (() -> Void)? = nil,
         onHeightChange: ((CGFloat) -> Void)? = nil,
         tracker: some AnalyticsTracking = DIContainer.tracker) {
        self.warningType = warningType
        self.router = router
        self.shouldShowCloseButton = shouldShowCloseButton
        self.closeButtonAction = closeButtonAction
        self.onHeightChange = onHeightChange
        self.tracker = tracker
        
        self.applyNewDesign = warningType == .fullStorageOverQuota || warningType == .almostFullStorageOverQuota
    }
    
    func onViewAppear() {
        switch warningType {
        case .fullStorageOverQuota:
            tracker.trackAnalyticsEvent(with: FullStorageOverQuotaBannerDisplayedEvent())
        case .almostFullStorageOverQuota:
            tracker.trackAnalyticsEvent(with: AlmostFullStorageOverQuotaBannerDisplayedEvent())
        default: break
        }
    }
    
    func onBannerTapped() {
        switch warningType {
        case .limitedPhotoAccess:
            router?.goToSettings()
        default: break
        }
    }
    
    func onCloseButtonTapped() {
        switch warningType {
        case .almostFullStorageOverQuota:
            tracker.trackAnalyticsEvent(with: AlmostFullStorageOverQuotaBannerCloseButtonPressedEvent())
        default: break
        }
        
        closeButtonAction?()
    }
    
    func onActionButtonTapped() {
        switch warningType {
        case .fullStorageOverQuota:
            tracker.trackAnalyticsEvent(with: FullStorageOverQuotaBannerUpgradeButtonPressedEvent())
            router?.presentUpgradeScreen()
        case .almostFullStorageOverQuota:
            tracker.trackAnalyticsEvent(with: AlmostFullStorageOverQuotaBannerUpgradeButtonPressedEvent())
            router?.presentUpgradeScreen()
        default: break
        }
    }
}
