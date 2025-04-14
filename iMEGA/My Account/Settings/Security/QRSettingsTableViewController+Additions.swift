import MEGAAppSDKRepo
import MEGADesignToken
import MEGADomain
import MEGAL10n
import UIKit

extension QRSettingsTableViewController {
    @objc func setupColors() {
        autoAcceptLabel?.textColor = TokenColors.Text.primary
        resetQRCodeLabel?.textColor = TokenColors.Text.error
        tableView.separatorColor = TokenColors.Border.strong
        tableView.backgroundColor = TokenColors.Background.page
    }
    
    open override func tableView(
        _ tableView: UITableView,
        willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        cell.backgroundColor = TokenColors.Background.page
    }
    
    @objc func makeViewModel() -> QRSettingsViewModel {
        let viewModel = QRSettingsViewModel(
            contactLinkVerificationUseCase: ContactLinkVerificationUseCase(
                repository: ContactLinkVerificationRepository.newRepo
            )
        )
        
        viewModel.invokeCommand = { [weak self] in self?.executeCommand($0) }
        return viewModel
    }
    
    @objc func configureObservers() {
        viewModel.dispatch(.onViewDidLoad)
    }
    
    @objc func resetContactLink() {
        viewModel.dispatch(.resetContactLink)
    }
    
    @objc func updateAutoAcceptStatus(_ enabled: Bool) {
        viewModel.dispatch(.autoAcceptDidChange(enabled))
    }
    
    func executeCommand(_ command: QRSettingsViewModel.Command) {
        switch command {
        case .refreshAutoAccept(let isEnabled):
            autoAcceptSwitch.isOn = isEnabled
        case .contactLinkReset:
            SVProgressHUD.showSuccess(withStatus: Strings.Localizable.resetQrCodeFooter)
        }
    }
}
