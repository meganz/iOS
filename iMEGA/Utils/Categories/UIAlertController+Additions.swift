import MEGADesignToken
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
        
        let discardAction = UIAlertAction(title: Strings.Localizable.discardChanges, style: .destructive) { _ in
            action()
        }
        
        discardAction.titleTextColor = TokenColors.Text.error
        
        alert.addAction(discardAction)
        alert.addAction(UIAlertAction(title: Strings.Localizable.cancel, style: .cancel))
        return alert
    }
    
    class func createAlert(
        forceDarkMode: Bool,
        title: String? = nil,
        message: String,
        preferredActionTitle: String,
        secondaryActionTitle: String,
        showNotNowAction: Bool = true,
        preferredActionEnabled: Bool = true,
        preferredAction: @escaping () -> Void,
        secondaryAction: @escaping () -> Void
    ) -> UIAlertController {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        
        let preferredAction = UIAlertAction(
            title: preferredActionTitle,
            style: .default
        ) { _ in
            preferredAction()
        }
        
        preferredAction.isEnabled = preferredActionEnabled
        
        alert.addAction(preferredAction)
        
        // this is done to make the disabled primary action button look somewhat different
        // than enabled one
        if preferredAction.isEnabled {
            alert.preferredAction = preferredAction
        } else {
            preferredAction.titleTextColor = TokenColors.Text.disabled
        }
        
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

extension UIAlertAction {
    var titleTextColor: UIColor? {
        get {
            return self.value(forKey: "titleTextColor") as? UIColor
        } set {
            self.setValue(newValue, forKey: "titleTextColor")
        }
    }
}
