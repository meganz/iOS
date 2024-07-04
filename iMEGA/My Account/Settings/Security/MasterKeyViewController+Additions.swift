import MEGADesignToken
import MEGAL10n
import UIKit

extension MasterKeyViewController {
    @objc func setupContent() {
        navigationItem.title = Strings.Localizable.recoveryKey
        carbonCopyMasterKeyButton?.setTitle(Strings.Localizable.copy, for: .normal)
        saveMasterKey?.setTitle(Strings.Localizable.save, for: .normal)

        whyDoINeedARecoveryKeyButton?.setTitle(Strings.Localizable.whyDoINeedARecoveryKey, for: .normal)

        whyDoINeedARecoveryKeyButton?.titleLabel?.numberOfLines = 0
        whyDoINeedARecoveryKeyButton?.titleLabel?.lineBreakMode = .byWordWrapping
        whyDoINeedARecoveryKeyButton?.titleLabel?.textAlignment = .center
    }

    @objc func updateAppearance() {
        view.backgroundColor = UIColor.isDesignTokenEnabled() ?
        TokenColors.Background.page : UIColor.systemBackground

        illustrationView?.backgroundColor = UIColor.isDesignTokenEnabled() ?
        TokenColors.Background.page : UIColor.mnz_backgroundGrouped(for: traitCollection)

        carbonCopyMasterKeyButton?.mnz_setupSecondary(traitCollection)
        saveMasterKey?.mnz_setupPrimary(traitCollection)

        let recoveryButtonColor = UIColor.isDesignTokenEnabled() ?
        TokenColors.Link.primary : UIColor.mnz_turquoise(for: traitCollection)

        whyDoINeedARecoveryKeyButton?.setTitleColor(recoveryButtonColor, for: .normal)
    }
}
