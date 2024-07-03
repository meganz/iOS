import MEGADesignToken
import UIKit

extension MasterKeyViewController {
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
