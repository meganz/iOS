extension UIAlertController {
    
    //MARK - UIAlertController for interactive dismissal
    
    @objc func discardChanges(fromBarButton barButton: UIBarButtonItem?, withConfirmAction action: @escaping (() -> Void)) -> UIAlertController {
        let alert = discardChangesAlert(withConfirmAction: action)
        alert.popoverPresentationController?.barButtonItem = barButton
        
        return alert
    }
    
    @objc func discardChanges(fromSourceView sourceView: UIView?, sourceRect: CGRect, withConfirmAction action: @escaping (() -> Void)) -> UIAlertController {
        let alert = discardChangesAlert(withConfirmAction: action)
        alert.popoverPresentationController?.sourceView = sourceView
        alert.popoverPresentationController?.sourceRect = sourceRect

        return alert
    }
    
    private func discardChangesAlert(withConfirmAction action: @escaping (() -> Void)) -> UIAlertController {
        let alert = UIAlertController(title: nil, message:nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: AMLocalizedString("Discard Changes", "Text used to notify the user that some action would discard a non ended action"), style: .destructive) { _ in
            action()
        })
        alert.addAction(UIAlertAction(title: AMLocalizedString("cancel", "Button title to cancel something"), style: .cancel))
        
        return alert
    }
}
