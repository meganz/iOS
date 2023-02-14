
extension VerifyCredentialsViewController: VerifyCredentialsViewProvider {
    var warningViewModel: WarningViewModel {
        WarningViewModel(warningType: .requiredIncomingSharedItemVerification,
                         router: WarningViewRouter(),
                         isShowCloseButton: true,
                         hideWarningViewAction: removeWarningView)
    }

    @objc func objcWrapper_configSharedItemWarningView() {
        configWarningView(in: incomingItemWarningView)
    }

    @objc func updateSharedItemWarningViewIfNeeded(previousTraitCollection: UITraitCollection?) {
        if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
            self.updateWarningViewSize()
        }
    }
}
