import KMTransferUtils
import MEGAAnalyticsiOS
import MEGAAppPresentation

extension AppDelegate {

    private static let usSessionLostReportedKey = "usSessionLostReported"

    @objc func importKMTransferFile() {
        do {
            try DIContainer.kmTransferUtils.importTransferFile()
            DIContainer.tracker.trackAnalyticsEvent(
                with: IOSKMTransferUSMigrationSucceededEvent()
            )
        } catch let error as KMTransferError {
            switch error {
            case .storageExistsDuringImportTransfer:
                break
            case .transferFileMissing:
                reportUSSessionLostIfNeeded()
            default:
                DIContainer.tracker.trackAnalyticsEvent(
                    with: IOSKMTransferUSMigrationFailedEvent(reason: Self.failureReason(for: error))
                )
            }
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

    // MARK: - Private

    private func reportUSSessionLostIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: Self.usSessionLostReportedKey),
              Self.hasPriorLoginEvidence()
        else { return }
        DIContainer.tracker.trackAnalyticsEvent(
            with: IOSKMTransferUSSessionLostEvent()
        )
        defaults.set(true, forKey: Self.usSessionLostReportedKey)
    }

    private static func hasPriorLoginEvidence() -> Bool {
        guard let appSupport = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first,
              let contents = try? FileManager.default.contentsOfDirectory(atPath: appSupport.path),
              let loginStateCache = try? Regex(#"megaclient_statecache\d+_(?:status_)?[A-Za-z0-9_-]{36}\.db(?:-wal|-shm|-journal)?"#)
        else { return false }
        return contents.contains { $0.wholeMatch(of: loginStateCache) != nil }
    }

    private static func failureReason(for error: KMTransferError) -> String {
        switch error {
        case .storageWriteFailure(let status):
            "writeFailure:\(status)"
        case .invalidStorageEntryFormat:
            "corruptBlob"
        case .transferFileTooSmall:
            "fileTooSmall"
        case .applicationSupportUnavailable:
            "appSupportUnavailable"
        default:
            "other"
        }
    }
}
