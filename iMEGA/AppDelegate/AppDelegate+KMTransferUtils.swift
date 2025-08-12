import MEGAAnalyticsiOS
import MEGAAppPresentation

extension AppDelegate {

    @objc func importKMTransferFile() {
        do {
            try DIContainer.kmTransferUtils.importTransferFile()
            DIContainer.tracker.trackAnalyticsEvent(
                with: IOSKMTransferImportedSuccessfullyEvent()
            )
        } catch {}
    }

    @objc func createKMTransferFile() {
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
