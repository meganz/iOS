import Foundation

extension CustomModalAlertViewController {
    func configureUpgradeToPro() {
        image = UIImage(named: "upgradePro")
        viewTitle = NSLocalizedString("Upgrade to Pro", comment: "Title of a warning recommending upgrade to Pro")
        detail = NSLocalizedString("Access Pro only features like setting password protection and expiry dates for public files.", comment: "A description of MEGA features available only with a Pro plan.")
        
        firstButtonTitle = NSLocalizedString("seePlans", comment: "Button title to see the available pro plans in MEGA")
        dismissButtonTitle = NSLocalizedString("notNow", comment: "Text indicating to the user that some action will be postpone. E.g. used for 'rich previews' and management of disk storage.")
        
        firstCompletion = { [weak self] in
            self?.dismiss(animated: true, completion: {
                UpgradeAccountRouter().presentUpgradeTVC()
            })
        }
        
        dismissCompletion = { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }
}
