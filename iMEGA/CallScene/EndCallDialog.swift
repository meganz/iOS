import UIKit

struct EndCallDialog {
    private var endCallDialogViewController: UIAlertController
    
    init(forceDarkMode: Bool = false, stayOnCallAction: @escaping () -> Void, endCallAction: @escaping () -> Void) {
        let endCallDialogViewController = UIAlertController(
            title: Strings.Localizable.Meetings.EndCallDialog.title,
            message: Strings.Localizable.Meetings.EndCallDialog.description,
            preferredStyle: .alert
        )
        
        endCallDialogViewController.addAction(
            UIAlertAction(
                title: Strings.Localizable.Meetings.EndCallDialog.stayOnCallButtonTitle,
                style: .cancel
            ) { _ in
                stayOnCallAction()
            }
        )
        
        let endCall = UIAlertAction(
            title: Strings.Localizable.Meetings.EndCallDialog.endCallNowButtonTitle,
            style: .default
        ) { _ in
            endCallAction()
        }
        
        endCallDialogViewController.addAction(endCall)
        endCallDialogViewController.preferredAction = endCall
        
        if forceDarkMode {
            endCallDialogViewController.overrideUserInterfaceStyle = .dark
        }
        
        self.endCallDialogViewController = endCallDialogViewController
    }
    
    func show(animated: Bool = true) {
        UIApplication.mnz_presentingViewController().present(endCallDialogViewController, animated: animated)
    }
    
    func dismiss(animated: Bool = true, completion: (() -> Void)? = nil) {
        endCallDialogViewController.dismiss(animated: animated, completion: completion)
    }
}
