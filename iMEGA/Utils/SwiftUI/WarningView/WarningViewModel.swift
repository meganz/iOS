enum WarningType: CustomStringConvertible {
    case noInternetConnection
    case limitedPhotoAccess
    
    var description: String {
        switch self {
        case .noInternetConnection: return Strings.Localizable.General.noIntenerConnection
        case .limitedPhotoAccess: return Strings.Localizable.CameraUploads.Warning.limitedAccessToPhotoMessage
        }
    }
}


@objc final class WarningViewModel: NSObject, ObservableObject {
    let warningType: WarningType
    let router: WarningViewRouting?
    
    init(warningType: WarningType, router: WarningViewRouting? = nil) {
        self.warningType = warningType
        self.router = router
    }
    
    func tapAction() {
        switch (warningType) {
        case.limitedPhotoAccess:
            router?.goToSettings()
        case.noInternetConnection: break
        }
    }
}
