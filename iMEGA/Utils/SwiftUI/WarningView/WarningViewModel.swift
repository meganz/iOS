import MEGAL10n

enum WarningType: CustomStringConvertible {
    case noInternetConnection
    case limitedPhotoAccess
    case contactsNotVerified
    case contactNotVerifiedSharedFolder(String)
    case backupStatusError(String)

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
        case .backupStatusError(let errorMessage):
            return errorMessage
        }
    }
}

@objc final class WarningViewModel: NSObject, ObservableObject {
    let warningType: WarningType
    let router: (any WarningViewRouting)?
    let isShowCloseButton: Bool
    var hideWarningViewAction: (() -> Void)?
    var onHeightChange: ((CGFloat) -> Void)?
    @Published var isHideWarningView: Bool = false
    
    init(warningType: WarningType,
         router: (any WarningViewRouting)? = nil,
         isShowCloseButton: Bool = false,
         hideWarningViewAction: (() -> Void)? = nil,
         onHeightChange: ((CGFloat) -> Void)? = nil) {
        self.warningType = warningType
        self.router = router
        self.isShowCloseButton = isShowCloseButton
        self.hideWarningViewAction = hideWarningViewAction
        self.onHeightChange = onHeightChange
    }
    
    func tapAction() {
        switch warningType {
        case .limitedPhotoAccess:
            router?.goToSettings()
        case .noInternetConnection,
             .contactsNotVerified,
             .contactNotVerifiedSharedFolder,
             .backupStatusError:
            break
        }
    }
    
    func closeAction() {
        isHideWarningView = true
        hideWarningViewAction?()
    }
}
