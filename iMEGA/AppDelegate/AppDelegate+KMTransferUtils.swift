import MEGAAnalyticsiOS
import MEGAAppPresentation

extension AppDelegate {
    private var isKMTransferEnabled: Bool {
        DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .kmTransfer)
    }

    @objc func importKMTransferFile() {
        guard isKMTransferEnabled else { return }
        do {
            try DIContainer.kmTransferUtils.importTransferFile()
            DIContainer.tracker.trackAnalyticsEvent(
                with: IOSKMTransferImportedSuccessfullyEvent()
            )
        } catch {}
    }

    @objc func createKMTransferFile() {
        guard isKMTransferEnabled else { return }
        Task {
            do {
                try await DIContainer.kmTransferUtils.createTransferFile()
                DIContainer.tracker.trackAnalyticsEvent(
                    with: IOSKMTransferCreatedSuccessfullyEvent()
                )
            } catch {}
        }
    }
}
