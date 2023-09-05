import MEGAL10n

enum WarningType: CustomStringConvertible {
    case noInternetConnection
    case limitedPhotoAccess
    case contactsNotVerified
    case contactNotVerifiedSharedFolder(String)

    var description: String {
        switch self {
        case .noInternetConnection:
            return Strings.Localizable.General.noIntenerConnection
        case .limitedPhotoAccess:
            return Strings.Localizable.CameraUploads.Warning.limitedAccessToPhotoMessage
        case .contactsNotVerified:
            return Strings.Localizable.ShareFolder.contactsNotVerified
        case .contactNotVerifiedSharedFolder(let nodeName):
            return Strings.Localizable.SharedItems.ContactVerification.contactNotVerifiedBannerMessage(nodeName)
        }
    }
}

@objc final class WarningViewModel: NSObject, ObservableObject {
    let warningType: WarningType
    let router: (any WarningViewRouting)?
    let isShowCloseButton: Bool
    var hideWarningViewAction: (() -> Void)?
    @Published var isHideWarningView: Bool = false
    
    init(warningType: WarningType,
         router: (any WarningViewRouting)? = nil,
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
             .contactsNotVerified,
             .contactNotVerifiedSharedFolder:
            break
        }
    }
    
    func closeAction() {
        isHideWarningView = true
        hideWarningViewAction?()
    }
}
