import MEGAAssets
import MEGADomain
import MEGAL10n

extension CustomModalAlertViewController {
    func configureForPendingUnverifiedOutshare(for email: String) {
        image = MEGAAssets.UIImage.verifyPendingOutshareEmail
        viewTitle = Strings.Localizable.SharedItems.Tab.Outgoing.Modal.CannotVerifyContact.title
        detail = Strings.Localizable.SharedItems.Tab.Outgoing.Modal.CannotVerifyContact.message(email)
        firstButtonTitle = Strings.Localizable.ok
        dismissButtonTitle = nil
        
        firstCompletion = { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }
}
