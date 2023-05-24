enum WarningType: CustomStringConvertible {
    case noInternetConnection
    case limitedPhotoAccess
    case requiredIncomingSharedItemVerification

    var description: String {
        switch self {
        case .noInternetConnection: return Strings.Localizable.General.noIntenerConnection
        case .limitedPhotoAccess: return Strings.Localizable.CameraUploads.Warning.limitedAccessToPhotoMessage
        case .requiredIncomingSharedItemVerification: return Strings.Localizable.SharedItems.ContactVerification.Section.VerifyContact.bannerMessage
        }
    }
}

@objc final class WarningViewModel: NSObject, ObservableObject {
    let warningType: WarningType
    let router: WarningViewRouting?
    let isShowCloseButton: Bool
    var hideWarningViewAction: (() -> Void)?
    @Published var isHideWarningView: Bool = false
    
    init(warningType: WarningType,
         router: WarningViewRouting? = nil,
         isShowCloseButton: Bool = false,
         hideWarningViewAction: (() -> Void)? = nil) {
        self.warningType = warningType
        self.router = router
        self.isShowCloseButton = isShowCloseButton
        self.hideWarningViewAction = hideWarningViewAction
    }
    
    func tapAction() {
        switch warningType {
        case .limitedPhotoAccess:
            router?.goToSettings()
        case .noInternetConnection,
             .requiredIncomingSharedItemVerification:
            break
        }
    }
    
    func closeAction() {
        isHideWarningView = true
        hideWarningViewAction?()
    }
}
