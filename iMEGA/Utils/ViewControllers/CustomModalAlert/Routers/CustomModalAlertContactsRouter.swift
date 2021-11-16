
import Foundation

@objc final class CustomModalAlertContactsRouter: CustomModalAlertRouter {
    
    private var email: String
    
    @objc init(_ mode: CustomModalAlertMode, email: String, presenter: UIViewController) {
        self.email = email
        
        super.init(mode, presenter: presenter)
    }
    
    override func build() -> UIViewController {
        let customModalAlertVC = CustomModalAlertViewController()
        switch mode {
        case .outgoingContactRequest:
            customModalAlertVC.configureOutgoingContactRequest(email)
            
        case .contactNotInMEGA:
            customModalAlertVC.configureContactNotInMEGA(email)
            
        default: break
        }
        
        return customModalAlertVC
    }
}
