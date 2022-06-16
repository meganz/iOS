import UIKit

final class EndCallDialog {
    
    //MARK: - Private properties

    private var endCallDialogViewController: UIAlertController?
    
    private var type: EndCallDialogType
    private var forceDarkMode: Bool
    private var autodismiss: Bool
    private var stayOnCallAction: () -> Void
    private var endCallAction: () -> Void
    
    //MARK: - Init

    init(type: EndCallDialogType = .endCallForMyself,
         forceDarkMode: Bool = false,
         autodismiss: Bool = false,
         stayOnCallAction: @escaping () -> Void,
         endCallAction: @escaping () -> Void) {
        
        self.type = type
        self.forceDarkMode = forceDarkMode
        self.autodismiss = autodismiss
        self.stayOnCallAction = stayOnCallAction
        self.endCallAction = endCallAction
    }
    
    //MARK: - Interface methods

    func show(animated: Bool = true) {
        let endCallDialogViewController = createDialog()
        self.endCallDialogViewController = endCallDialogViewController
        UIApplication.mnz_presentingViewController().present(endCallDialogViewController, animated: animated)
    }
    
    func dismiss(animated: Bool = true, completion: (() -> Void)? = nil) {
        endCallDialogViewController?.dismiss(animated: animated, completion: completion)
    }
    
    //MARK: - Private methods
    
    private func createDialog() -> UIAlertController {
        let endCallDialogViewController = UIAlertController(
            title: type.title,
            message: type.message,
            preferredStyle: .alert
        )
        
        endCallDialogViewController.addAction(
            UIAlertAction(
                title: type.cancelTitle,
                style: .cancel
            ) { [weak self] _ in
                guard let self = self else { return }
                self.stayOnCallAction()
            }
        )
        
        let endCall = UIAlertAction(
            title: type.endCallTitle,
            style: .default
        ) { [weak self] _ in
            guard let self = self else { return }
            self.endCallAction()
            if self.autodismiss {
                self.endCallDialogViewController?.dismiss(animated: true)
            }
        }
        
        endCallDialogViewController.addAction(endCall)
        endCallDialogViewController.preferredAction = endCall
        
        if forceDarkMode {
            endCallDialogViewController.overrideUserInterfaceStyle = .dark
        }
        
        return endCallDialogViewController
    }
}
