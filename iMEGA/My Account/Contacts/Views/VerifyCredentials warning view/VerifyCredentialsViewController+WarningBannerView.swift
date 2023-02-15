
extension VerifyCredentialsViewController: VerifyCredentialsViewProvider {
    var warningViewModel: WarningViewModel {
        WarningViewModel(warningType: .requiredIncomingSharedItemVerification,
                         router: WarningViewRouter(),
                         isShowCloseButton: true,
                         hideWarningViewAction: removeWarningView)
    }

    @objc func objcWrapper_configSharedItemWarningView() {
        guard isIncomingSharedItem else { return }
        configWarningView(in: incomingItemWarningView)
    }

    @objc func updateSharedItemWarningViewIfNeeded(previousTraitCollection: UITraitCollection?) {
        guard isIncomingSharedItem else { return }
        if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
            self.updateWarningViewSize()
        }
    }
}
