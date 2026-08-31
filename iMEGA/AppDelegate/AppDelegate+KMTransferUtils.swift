import KMTransferUtils
import MEGAAnalyticsiOS
import MEGAAppPresentation
import os
import Security

private let migrationLog = Logger(subsystem: "mega.ios.migration", category: "app")

extension AppDelegate {

    private static let usSessionLostReportedKey = "usSessionLostReported"

    @objc func importKMTransferFile() {
        Self.logMigrationState("pre")
        do {
            try DIContainer.kmTransferUtils.importTransferFile()
            migrationLog.error("import succeeded")
            Self.logMigrationState("post")
            DIContainer.tracker.trackAnalyticsEvent(
                with: IOSKMTransferUSMigrationSucceededEvent()
            )
        } catch let error as KMTransferError {
            switch error {
            case .storageExistsDuringImportTransfer:
                migrationLog.error("import skipped: storage already populated")
            case .transferFileMissing:
                migrationLog.error("import skipped: no backup file")
                reportUSSessionLostIfNeeded()
            default:
                migrationLog.error("import failed: \(Self.failureReason(for: error), privacy: .public)")
                DIContainer.tracker.trackAnalyticsEvent(
                    with: IOSKMTransferUSMigrationFailedEvent(reason: Self.failureReason(for: error))
                )
            }
        } catch {
            migrationLog.error("import failed: \(String(describing: error), privacy: .public)")
        }
    }

    @objc func createKMTransferFile() {
        Task {
            do {
                try await DIContainer.kmTransferUtils.createTransferFile()
                migrationLog.error("backup created")
                DIContainer.tracker.trackAnalyticsEvent(
                    with: IOSKMTransferCreatedSuccessfullyEvent()
                )
            } catch KMTransferError.transferFileExistDuringExport {
                migrationLog.error("backup create skipped: file already exists")
            } catch let error as KMTransferError {
                migrationLog.error("backup create failed: \(Self.failureReason(for: error), privacy: .public)")
            } catch {
                migrationLog.error("backup create failed: \(String(describing: error), privacy: .public)")
            }
        }
    }

    // MARK: - Private

    private func reportUSSessionLostIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: Self.usSessionLostReportedKey),
              Self.hasPriorLoginEvidence()
        else { return }
        migrationLog.error("session lost: prior login evidence without backup")
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

    // MARK: - Diagnostics

    private static func logMigrationState(_ stage: String) {
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "-"
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "-"
        migrationLog.error("\(stage, privacy: .public): v\(version, privacy: .public)(\(build, privacy: .public)) defaultGroup=\(defaultAccessGroup(), privacy: .public)")

        for account in ["sessionV3", "statsid"] {
            let (status, agrp, data) = keychainItem(service: "MEGA", account: account)
            let detail = account == "sessionV3"
                ? "len=\(data?.count ?? 0)B"
                : "id8=\(String(decoding: (data ?? Data()).prefix(8), as: UTF8.self))"
            migrationLog.error("\(stage, privacy: .public): \(account, privacy: .public) status=\(status, privacy: .public) agrp=\(agrp, privacy: .public) \(detail, privacy: .public)")
        }
        migrationLog.error("\(stage, privacy: .public): passcodeItems=\(itemCount(service: "demoServiceName"), privacy: .public)")
        let (pinStatus, _, pinData) = keychainItem(service: "demoServiceName", account: "demoPasscode")
        var passcodeDetail = "pin status=\(pinStatus) len=\(pinData?.count ?? 0)B"
        for account in ["passcodeTimerDuration", "passcodeIsSimple", "passcodeType"] {
            let (_, _, data) = keychainItem(service: "demoServiceName", account: account)
            let value = data.map { String(decoding: $0, as: UTF8.self) } ?? "-"
            passcodeDetail += " \(account)=\(value)"
        }
        migrationLog.error("\(stage, privacy: .public): \(passcodeDetail, privacy: .public)")

        if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let backup = appSupport.appendingPathComponent("km_transfer")
            let attrs = try? FileManager.default.attributesOfItem(atPath: backup.path)
            let size = (attrs?[.size] as? Int) ?? 0
            let mtime = (attrs?[.modificationDate] as? Date).map { "\($0.timeIntervalSince1970)" } ?? "-"
            let records = (try? DIContainer.kmTransferUtils.getDataFromTransferFile().count).map(String.init) ?? "-"
            migrationLog.error("\(stage, privacy: .public): backup exists=\(attrs != nil, privacy: .public) size=\(size, privacy: .public)B mtime=\(mtime, privacy: .public) records=\(records, privacy: .public)")

            let entries = (try? FileManager.default.contentsOfDirectory(atPath: appSupport.path)) ?? []
            let transfers = entries.filter { $0.contains("_transfers_") }
            let statecaches = entries.filter { $0.hasPrefix("megaclient_statecache") && !$0.contains("_transfers_") }.count
            let karere = entries.filter { $0.hasPrefix("karere") }.count
            let transferBytes = transfers.reduce(0) { total, name in
                total + (((try? FileManager.default.attributesOfItem(atPath: appSupport.appendingPathComponent(name).path))?[.size] as? Int) ?? 0)
            }
            migrationLog.error("\(stage, privacy: .public): appSupport statecache=\(statecaches, privacy: .public) karere=\(karere, privacy: .public) transfersDB=\(transfers.count, privacy: .public)/\(transferBytes, privacy: .public)B")
        } else {
            migrationLog.error("\(stage, privacy: .public): appSupport unresolved")
        }

        if let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let count = (try? FileManager.default.contentsOfDirectory(atPath: docs.path))?.count ?? -1
            migrationLog.error("\(stage, privacy: .public): documents entries=\(count, privacy: .public)")
        }
        let cameraUploads = UserDefaults.standard.bool(forKey: "IsCameraUploadsEnabled")
        migrationLog.error("\(stage, privacy: .public): cameraUploads=\(cameraUploads, privacy: .public)")

        if let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.mega.ios") {
            let support = container.appendingPathComponent("GroupSupport")
            let entries = (try? FileManager.default.contentsOfDirectory(atPath: support.path)) ?? []
            let megacd = ((try? FileManager.default.attributesOfItem(atPath: support.appendingPathComponent("MEGACD.sqlite").path))?[.size] as? Int) ?? 0
            let firstRun = UserDefaults(suiteName: "group.mega.ios")?.string(forKey: "FirstRun") ?? "-"
            migrationLog.error("\(stage, privacy: .public): group=\(container.lastPathComponent, privacy: .public) groupSupport=\(entries.count, privacy: .public) megacd=\(megacd, privacy: .public)B firstRun=\(firstRun, privacy: .public)")
        } else {
            migrationLog.error("\(stage, privacy: .public): group unresolved")
        }
    }

    private static func keychainItem(service: String, account: String) -> (OSStatus, String, Data?) {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnAttributes: true,
            kSecReturnData: true
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        let attrs = result as? [CFString: Any]
        return (status, attrs?[kSecAttrAccessGroup] as? String ?? "-", attrs?[kSecValueData] as? Data)
    }

    // A plain count would collapse "keychain readable but empty" and "read failed
    // (locked device, access-group issue)" into the same 0 — keep them apart.
    private static func itemCount(service: String) -> String {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: service,
            kSecMatchLimit: kSecMatchLimitAll,
            kSecReturnAttributes: true
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch status {
        case errSecSuccess:
            return "\((result as? [[CFString: Any]])?.count ?? 0)"
        case errSecItemNotFound:
            return "0"
        default:
            return "err:\(status)"
        }
    }

    private static func defaultAccessGroup() -> String {
        let identity: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: "mega.ios.migration",
            kSecAttrAccount: "accessGroupProbe"
        ]
        SecItemDelete(identity as CFDictionary)
        var probe = identity
        probe[kSecValueData] = Data([1])
        probe[kSecReturnAttributes] = true
        var result: AnyObject?
        let status = SecItemAdd(probe as CFDictionary, &result)
        defer { SecItemDelete(identity as CFDictionary) }
        guard status == errSecSuccess,
              let attrs = result as? [CFString: Any],
              let group = attrs[kSecAttrAccessGroup] as? String
        else { return "unresolved:\(status)" }
        return group
    }
}
