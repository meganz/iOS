
import Foundation

@objc enum CustomModalAlertMode: Int {
    case storageEvent = 0
    case storageQuotaError
    case storageUploadQuotaError
    case storageDownloadQuotaError
    case businessGracePeriod
    case outgoingContactRequest
    case contactNotInMEGA
}

@objc class CustomModalAlertRouter: NSObject, Routing {
    
    private weak var presenter: UIViewController?
    
    internal var mode: CustomModalAlertMode
    
    @objc init(_ mode: CustomModalAlertMode, presenter: UIViewController) {
        self.mode = mode
        self.presenter = presenter
    }
    
    func build() -> UIViewController {
        let customModalAlertVC = CustomModalAlertViewController()
        switch mode {
        case .storageQuotaError:
            customModalAlertVC.configureForStorageQuotaError(false)
            
        case .storageUploadQuotaError:
            customModalAlertVC.configureForStorageQuotaError(true)
            
        case .storageDownloadQuotaError:
            customModalAlertVC.configureForStorageDownloadQuotaError()
            
        case .businessGracePeriod:
            customModalAlertVC.configureForBusinessGracePeriod()
            
        default: break
        }
        
        return customModalAlertVC
    }
    
    @objc func start() {
        let visibleViewController = UIApplication.mnz_visibleViewController()
        if visibleViewController is CustomModalAlertViewController ||
           visibleViewController is UpgradeTableViewController ||
           visibleViewController is ProductDetailViewController {
            return
        }
        
        presenter?.present(build(), animated: true, completion: nil)
    }
}
