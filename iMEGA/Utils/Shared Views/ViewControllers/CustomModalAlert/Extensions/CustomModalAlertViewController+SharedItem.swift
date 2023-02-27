import MEGADomain

extension CustomModalAlertViewController {
    func configureForPendingUnverifiedOutshare(for email: String) {
        image = Asset.Images.SharedItems.verifyPendingOutshareEmail.image
        viewTitle = Strings.Localizable.SharedItems.Tab.Outgoing.Modal.CannotVerifyContact.title
        detail = Strings.Localizable.SharedItems.Tab.Outgoing.Modal.CannotVerifyContact.message(email)
        firstButtonTitle = Strings.Localizable.ok
        dismissButtonTitle = nil
        
        firstCompletion = { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }
}
