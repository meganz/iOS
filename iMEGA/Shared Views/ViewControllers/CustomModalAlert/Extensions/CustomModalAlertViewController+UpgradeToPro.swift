import Foundation

extension CustomModalAlertViewController {
    func configureUpgradeToPro() {
        image = Asset.Images.Pro.upgradePro.image
        viewTitle = Strings.Localizable.upgradeToPro
        detail = Strings.Localizable.accessProOnlyFeaturesLikeSettingPasswordProtectionAndExpiryDatesForPublicFiles
        
        firstButtonTitle = Strings.Localizable.seePlans
        dismissButtonTitle = Strings.Localizable.notNow
        
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
