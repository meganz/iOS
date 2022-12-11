
extension VerifyCredentialsViewController: VerifyCredentialsViewProvider {
    var warningViewModel: WarningViewModel {
        WarningViewModel(warningType: .requiredIncomingSharedItemVerification,
                         router: WarningViewRouter(),
                         isShowCloseButton: true,
                         hideWarningViewAction: removeWarningView)
    }

    @objc func objcWrapper_configSharedItemWarningView() {
        guard isShowIncomingItemWarningView else { return }
        configWarningView(in: incomingItemWarningView)
    }

    @objc func updateSharedItemWarningViewIfNeeded(previousTraitCollection: UITraitCollection?) {
        guard isShowIncomingItemWarningView else { return }
        if traitCollection.preferredContentSizeCategory != previousTraitCollection?.preferredContentSizeCategory {
            self.updateWarningViewSize()
        }
    }
}
