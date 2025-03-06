import Accounts
import Foundation
import MEGADomain
import MEGAPresentation

@objc enum CustomModalAlertMode: Int {
    case storageEvent = 0
    case storageQuotaError
    case storageUploadQuotaError
    case transferDownloadQuotaError
    case businessGracePeriod
    case outgoingContactRequest
    case contactNotInMEGA
    case enableKeyRotation
    case upgradeSecurity
    case pendingUnverifiedOutShare
    case cancelSubscription
    case cancelSubscriptionError
}

@objc class CustomModalAlertRouter: NSObject, Routing {
    
    private weak var presenter: UIViewController?
    
    internal var mode: CustomModalAlertMode
    
    private var chatId: ChatIdEntity?
    
    private var outShareEmail: String?
    
    private var expirationDate: Date?
    private var storageLimit: Int?
    
    private var transferQuotaDisplayMode: CustomModalAlertView.Mode.TransferQuotaErrorDisplayMode?
    
    /// An action handler that executes an action and calls a completion handler when finished.
    private var actionHandlerWithCompletion: ((@escaping () -> Void) -> Void)?
    /// A simple dismiss handler.
    private var actionHandler: (() -> Void)?
    private var dismissHandler: (() -> Void)?
    
    @objc init(_ mode: CustomModalAlertMode, presenter: UIViewController) {
        self.mode = mode
        self.presenter = presenter
    }
    
    init(_ mode: CustomModalAlertMode, presenter: UIViewController, chatId: ChatIdEntity) {
        self.mode = mode
        self.presenter = presenter
        self.chatId = chatId
    }
    
    init(_ mode: CustomModalAlertMode, presenter: UIViewController, outShareEmail: String) {
        self.mode = mode
        self.presenter = presenter
        self.outShareEmail = outShareEmail
    }
    
    init(_ mode: CustomModalAlertMode,
         presenter: UIViewController,
         transferQuotaDisplayMode: CustomModalAlertView.Mode.TransferQuotaErrorDisplayMode,
         actionHandler: @escaping (@escaping () -> Void) -> Void,
         dismissHandler: @escaping () -> Void
    ) {
        self.mode = mode
        self.presenter = presenter
        self.transferQuotaDisplayMode = transferQuotaDisplayMode
        self.actionHandlerWithCompletion = actionHandler
        self.dismissHandler = dismissHandler
    }
    
    init (
        _ mode: CustomModalAlertMode,
        presenter: UIViewController,
        expirationDate: Date,
        storageLimit: Int
    ) {
        self.mode = mode
        self.presenter = presenter
        self.expirationDate = expirationDate
        self.storageLimit = storageLimit
    }
    
    init(
        _ mode: CustomModalAlertMode,
        presenter: UIViewController,
        actionHandler: @escaping () -> Void
    ) {
        self.mode = mode
        self.presenter = presenter
        self.actionHandler = actionHandler
    }
    
    func build() -> UIViewController {
        let customModalAlertVC = CustomModalAlertViewController()
        switch mode {
        case .storageQuotaError, .storageUploadQuotaError:
            customModalAlertVC.configureForStorageQuotaError(false)

        case .transferDownloadQuotaError:
            guard let transferDisplayMode = transferQuotaDisplayMode else { return customModalAlertVC }
            customModalAlertVC.configureForTransferQuotaError(
                for: transferDisplayMode,
                actionHandler: actionHandlerWithCompletion,
                dismissHandler: dismissHandler
            )
             
        case .businessGracePeriod:
            customModalAlertVC.configureForBusinessGracePeriod()
            
        case .enableKeyRotation:
            guard let chatId else { return customModalAlertVC }
            customModalAlertVC.configureForEnableKeyRotation(in: chatId)
        
        case .upgradeSecurity:
            customModalAlertVC.configureForUpgradeSecurity()
        
        case .pendingUnverifiedOutShare:
            guard let outShareEmail else { return customModalAlertVC }
            customModalAlertVC.configureForPendingUnverifiedOutshare(for: outShareEmail)
            
        case .cancelSubscription:
            guard let expirationDate, let storageLimit else { return customModalAlertVC }
            customModalAlertVC.configureForCancelSubscriptionConfirmation(expirationDate: expirationDate, storageLimit: storageLimit)
        case .cancelSubscriptionError:
            guard let actionHandler else { return customModalAlertVC }
            customModalAlertVC.configureForCancelSubscriptionFailure(actionHandler: actionHandler)
            
        default: break
        }
        
        return customModalAlertVC
    }
    
    @objc func start() {
        let visibleViewController = UIApplication.mnz_visibleViewController()
        if mode != .upgradeSecurity &&
            (visibleViewController is CustomModalAlertViewController ||
             visibleViewController is UpgradeTableViewController ||
             visibleViewController is ProductDetailViewController) {
            return
        }
        
        presenter?.present(build(), animated: true, completion: nil)
    }
}
