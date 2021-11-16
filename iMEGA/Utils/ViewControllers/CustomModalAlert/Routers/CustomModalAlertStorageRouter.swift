
import Foundation

@objc final class CustomModalAlertStorageRouter: CustomModalAlertRouter {
    
    private var event: MEGAEvent
    
    @objc init(_ mode: CustomModalAlertMode, event: MEGAEvent, presenter: UIViewController) {
        self.event = event
        
        super.init(mode, presenter: presenter)
    }
    
    override func build() -> UIViewController {
        let customModalAlertVC = CustomModalAlertViewController()
        switch mode {
        case .storageEvent:
            customModalAlertVC.configureForStorageEvent(event)
            
        default: break
        }
        
        return customModalAlertVC
    }
}
