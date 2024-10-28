import Foundation
import MEGAL10n

extension CustomModalAlertViewController {
    func configureForCancelSubscriptionConfirmation(expirationDate: Date, storageLimit: Int) {
        let dateString = expirationDate.string(withDateFormat: "dd/MM/yy")
        viewTitle = Strings.Localizable.Accounts.CancelSubscriptionConfirmationAlert.title
        
        let storageLimitCapacity = Strings.Localizable.Storage.Limit.capacity(storageLimit)
        detail = "\(Strings.Localizable.Accounts.CancelSubscriptionConfirmationAlert.Description.currentPlanExpiration(dateString))\n\n\(Strings.Localizable.Accounts.CancelSubscriptionConfirmationAlert.Description.storageLimit(storageLimitCapacity))"
        
        dismissButtonTitle = Strings.Localizable.Accounts.CancelSubscriptionConfirmationAlert.Button.title
        dismissButtonStyle = MEGACustomButtonStyle.primary.rawValue
        firstCompletion = { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }
}
