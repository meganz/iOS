import Foundation
import MEGAAssets
import MEGAL10n

extension CustomModalAlertViewController {
    func configureUpgradeToPro(onConfirm: @escaping () -> Void, onCancel: @escaping () -> Void) {
        image = MEGAAssets.UIImage.upgradePro
        viewTitle = Strings.Localizable.upgradeToPro
        detail = Strings.Localizable.accessProOnlyFeaturesLikeSettingPasswordProtectionAndExpiryDatesForPublicFiles
        
        firstButtonTitle = Strings.Localizable.seePlans
        dismissButtonTitle = Strings.Localizable.notNow
        
        firstCompletion = { [weak self] in
            self?.dismiss(animated: true, completion: {
                onConfirm()
                UpgradeAccountRouter().presentUpgradeTVC()
            })
        }
        
        dismissCompletion = { [weak self] in
            onCancel()
            self?.dismiss(animated: true, completion: nil)
        }
    }
}
