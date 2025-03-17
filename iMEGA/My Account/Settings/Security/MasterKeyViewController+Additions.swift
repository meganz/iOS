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

    @objc func setupColors() {
        view.backgroundColor = TokenColors.Background.page

        illustrationView?.backgroundColor = TokenColors.Background.page

        carbonCopyMasterKeyButton?.mnz_setupSecondary()
        saveMasterKey?.mnz_setupPrimary()

        let recoveryButtonColor = TokenColors.Link.primary 

        whyDoINeedARecoveryKeyButton?.setTitleColor(recoveryButtonColor, for: .normal)
    }
    
    @objc func dispatchOnViewDidLoadAction() {
        viewModel.dispatch(.onViewDidLoad)
    }
    
    @objc func dispatchTapCopyAction() {
        viewModel.dispatch(.didTapCopyButton)
    }
    
    @objc func dispatchTapSaveAction() {
        viewModel.dispatch(.didTapSaveButton)
    }
    
    @objc func dispatchTapWhyDoINeedARecoveryKeyAction() {
        viewModel.dispatch(.didTapWhyDoINeedARecoveryKey)
    }
}
