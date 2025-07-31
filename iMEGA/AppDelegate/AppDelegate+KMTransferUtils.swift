import MEGAAppPresentation

extension AppDelegate {
    private var isKMTransferEnabled: Bool {
        DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .kmTransfer)
    }

    @objc func importKMTransferFile() {
        guard isKMTransferEnabled else { return }
        do {
            try DIContainer.kmTransferUtils.importTransferFile()
            // Add analytics
        } catch {}
    }
}
