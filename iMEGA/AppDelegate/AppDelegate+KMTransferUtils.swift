import CryptoKit
import KMTransferUtils
import MEGAAnalyticsiOS
import MEGAAppPresentation
import os
import Security

private let migrationLog = Logger(subsystem: "mega.ios.migration", category: "app")

extension AppDelegate {

    @objc func importKMTransferFile() {
        // The analytics below only count the app-transfer moment: the first launch under a new
        // team prefix. It is detected by a keychain marker in the team-prefixed access group —
        // absent exactly once after a transfer (the old marker is unreadable under the new
        // prefix), untouched by logout and reinstall. Same-team launches (re-imports after a
        // logout, QA cycles) keep their logs but track nothing.
        let markerStatus = Helper.teamMarkerStatus()
        let isCrossTeamLaunch = markerStatus == errSecItemNotFound
        defer {
            if isCrossTeamLaunch {
                Helper.writeTeamMarker()
            }
        }

        Self.logMigrationState("pre")
        do {
            try DIContainer.kmTransferUtils.importTransferFile()
            migrationLog.error("import succeeded crossTeam=\(isCrossTeamLaunch, privacy: .public)")
            Self.logMigrationState("post")
            // Not tracked here: the fastLogin that follows runs locallogout, which clears every
            // SDK command still queued. handlePostLoginSetup sends it once login completed.
            if isCrossTeamLaunch {
                Helper.markMigrationSucceededPending()
            }
        } catch let error as KMTransferError {
            switch error {
            case .storageExistsDuringImportTransfer:
                migrationLog.error("import skipped: storage already populated")
            case .transferFileMissing:
                migrationLog.error("import skipped: no backup file crossTeam=\(isCrossTeamLaunch, privacy: .public)")
                if isCrossTeamLaunch {
                    reportUSSessionLostIfNeeded()
                }
            default:
                // Safe to track right away: a failed import restores no session, so no fastLogin follows.
                migrationLog.error("import failed: \(Self.failureReason(for: error), privacy: .public)")
                if isCrossTeamLaunch {
                    DIContainer.tracker.trackAnalyticsEvent(
                        with: IOSKMTransferUSMigrationFailedEvent(reason: Self.failureReason(for: error))
                    )
                }
            }
        } catch {
            // Everything the framework models is taken by the typed catch above, so only its two
            // raw error sources reach here, both inside readTransferFile(): the Data(contentsOf:)
            // read and the AES-GCM decrypt
            let reason: String
            switch try? DIContainer.kmTransferUtils.getDataFromTransferFile() {
            case .some(let records) where records.isEmpty:
                reason = "backupEmpty"
            case .some:
                reason = "backupReadable"
            case .none:
                reason = switch error {
                case is CryptoKitError: "backupUndecryptable"
                case let readError as CocoaError: "backupUnreadable:\(readError.errorCode)"
                // Neither family: name the type, so a framework or SDK change that starts
                // throwing something else is visible instead of hiding in one opaque bucket.
                default: "unexpected:\(type(of: error))"
                }
            }
            migrationLog.error("import failed: \(String(describing: error), privacy: .public) \(reason, privacy: .public)")
            if isCrossTeamLaunch {
                DIContainer.tracker.trackAnalyticsEvent(
                    with: IOSKMTransferUSMigrationFailedEvent(reason: reason)
                )
            }
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
            } catch KMTransferError.storageDoesNotExist {
                // Nothing to back up yet (e.g. create ran before the session was written); the
                // next fast-login creates it.
                migrationLog.error("backup create skipped: nothing to back up yet")
            } catch let error as KMTransferError {
                migrationLog.error("backup create failed: \(Self.failureReason(for: error), privacy: .public)")
            } catch {
                migrationLog.error("backup create failed: \(String(describing: error), privacy: .public)")
            }
        }
    }

    // MARK: - Private

    /// Only reached on a cross-team first launch that found no backup file: the user was
    /// logged in before the upgrade and the session cannot be restored.
    private func reportUSSessionLostIfNeeded() {
        guard !Helper.hasReportedSessionLost,
              Self.hasPriorLoginEvidence()
        else { return }

        // The framework only throws transferFileMissing when sessionV3 is already absent in the
        // current group; assert it so a future reordering cannot turn this into a false positive.
        let (sessionStatus, _, _) = Self.keychainItem(service: "MEGA", account: "sessionV3")
        guard sessionStatus == errSecItemNotFound else {
            migrationLog.error("session-lost check skipped: sessionV3 status=\(sessionStatus, privacy: .public)")
            return
        }

        migrationLog.error("session lost: cross-team launch, prior login evidence, no backup, session unreadable")
        // Safe to send now: no session was restored, so no fastLogin/locallogout follows on this launch.
        DIContainer.tracker.trackAnalyticsEvent(
            with: IOSKMTransferUSSessionLostEvent()
        )
        Helper.markSessionLostReported()
    }

    private static func hasPriorLoginEvidence() -> Bool {
        // Main statecache DB only: a live login always has it, and the SDK removes the
        // -wal/-shm/-journal sidecars together with it, so matching them adds nothing.
        guard let appSupport = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first,
              let contents = try? FileManager.default.contentsOfDirectory(atPath: appSupport.path),
              let loginStateCache = try? Regex(#"megaclient_statecache\d+_(?:status_)?[A-Za-z0-9_-]{36}\.db"#)
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
        case .storageDoesNotExist:
            "nothingToBackUp"
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
        // Log-only probe, but AfterFirstUnlock keeps it resolvable on locked background launches.
        probe[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlock
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
