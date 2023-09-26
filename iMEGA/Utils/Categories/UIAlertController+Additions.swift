import MEGAL10n

extension UIAlertController {
    
    // MARK: - UIAlertController for interactive dismissal
    
    @objc func discardChanges(fromBarButton barButton: UIBarButtonItem, withConfirmAction action: @escaping (() -> Void)) -> UIAlertController {
        let alert = discardChangesAlert(withConfirmAction: action)
        alert.popoverPresentationController?.barButtonItem = barButton
        
        return alert
    }
    
    @objc func discardChanges(fromSourceView sourceView: UIView, sourceRect: CGRect, withConfirmAction action: @escaping (() -> Void)) -> UIAlertController {
        let alert = discardChangesAlert(withConfirmAction: action)
        alert.popoverPresentationController?.sourceView = sourceView
        alert.popoverPresentationController?.sourceRect = sourceRect

        return alert
    }
    
    private func discardChangesAlert(withConfirmAction action: @escaping (() -> Void)) -> UIAlertController {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: Strings.Localizable.discardChanges, style: .destructive) { _ in
            action()
        })
        alert.addAction(UIAlertAction(title: Strings.Localizable.cancel, style: .cancel))
        
        return alert
    }
    
    class func createAlert(forceDarkMode: Bool,
                           message: String,
                           preferredActionTitle: String,
                           secondaryActionTitle: String,
                           showNotNowAction: Bool = true,
                           preferredAction: @escaping () -> Void,
                           secondaryAction: @escaping () -> Void) -> UIAlertController {
        let alert = UIAlertController(
            title: nil,
            message: message,
            preferredStyle: .alert
        )
        
        let preferredAction = UIAlertAction(
            title: preferredActionTitle,
            style: .default
        ) { _ in
            preferredAction()
        }
        
        alert.addAction(preferredAction)
        
        alert.preferredAction = preferredAction
        
        alert.addAction(
            UIAlertAction(
                title: secondaryActionTitle,
                style: .default
            ) { _ in
                secondaryAction()
            }
        )
        
        if showNotNowAction {
            alert.addAction(
                UIAlertAction(
                    title: Strings.Localizable.notNow,
                    style: .cancel
                )
            )
        }
        
        if forceDarkMode {
            alert.overrideUserInterfaceStyle = .dark
        }
        
        return alert
    }
}
