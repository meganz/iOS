import Foundation
import LogRepo
import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAInfrastructure
import MEGAPreference
import MEGARepo
import MEGASwift
import Security

extension Helper {
    /// Temporary method to cache value of the AB test, we need this immediately after app is launched
    /// and every time user navigates anywhere in the folder tree
    /// Caching this in the UserDefault until we can access those flags without sprinkling async await everywhere
    static let CloudDriveABTestCacheKey = "ab_test_new_cloud_drive"
    
    static func cloudDriveABTestCacheKey() -> String {
        "ab_test_new_cloud_drive"
    }
    @objc static func cleanAccount() async {
        let uc = AccountCleanerUseCase(credentialRepo: CredentialRepository.newRepo,
                                       groupContainerRepo: AppGroupContainerRepository.newRepo)
        
        uc.cleanCredentialSessions()
        await uc.cleanAppGroupContainer()
        UserDefaults.standard.setValue(nil, forKey: cloudDriveABTestCacheKey())
    }
    
    @objc static func markAppAsLaunched() {
        AppFirstLaunchUseCase(preferenceUserCase: PreferenceUseCase.group).markAppAsLaunched()
    }
    
    @objc static func removeLogsDirectory() {
        Logger.shared().removeLogsDirectory()
    }

    @objc static func showStorageFullAlertView(requiredStorage: Int64) {
        StorageFullModalAlertViewRouter(requiredStorage: requiredStorage).startIfNeeded()
    }

    @objc static func deleteKMTransferFile() {
        try? DIContainer.kmTransferUtils.deleteTransferFile()
    }
}

// MARK: - Feature Flags

extension Helper {
    // As we're using the same MEGA group identifier for both preferences and as a
    // mean to cache FFs (currently only used in Development and QA) in UserDefaults
    // upon a logout, we need to re-inject them in the shared defaults again
    private static let _cachedFeatureFlags = Atomic<[String: Any]>(wrappedValue: [:])
    private static var cachedFeatureFlags: [String: Any] {
        get { _cachedFeatureFlags.wrappedValue }
        set { _cachedFeatureFlags.mutate { $0 = newValue } }
    }
    
    @objc static func injectCachedFeatureFlags() {
        let userDefaults = UserDefaults(suiteName: MEGAGroupIdentifier)
        userDefaults?.set(cachedFeatureFlags, forKey: MEGAFeatureFlagsUserDefaultsKey)
    }

    @objc static func cacheFeatureFlags() {
        let userDefaults = UserDefaults(suiteName: MEGAGroupIdentifier)
        let featureFlagsObject = userDefaults?.object(forKey: MEGAFeatureFlagsUserDefaultsKey)

        guard let featureFlags = featureFlagsObject as? [String: Any] else {
            return
        }

        cachedFeatureFlags = featureFlags
    }
}

// MARK: - Transfers

extension Helper {
    @objc static func areQueuedTransfersPaused() -> Bool {
        let transfersListenerUseCase = TransfersListenerUseCase(
            repo: TransfersListenerRepository.newRepo,
            preferenceUseCase: PreferenceUseCase.default
        )
        
        return transfersListenerUseCase.areQueuedTransfersPaused()
    }
}

extension Helper {
    @objc static func markRemoteFeatureFlagAsLoading() {
        Task {
            await RemoteFeatureFlagReadySource.shared.markAsLoading()
        }
    }
}

// MARK: - US migration analytics state

extension Helper {
    /// Device-level state for the app-transfer analytics, kept as keychain items in the default,
    /// team-prefixed access group under one service.
    ///
    /// The keychain is used on purpose: `Helper.logout` wipes `UserDefaults.standard`
    /// (`removePersistentDomain`), and the paths these flags must survive — an `ESID` on the
    /// restored session, a logout between launches — all go through it. Keychain items also
    /// survive a reinstall, which is what makes the team marker a reliable transfer detector.
    private enum MigrationMarker: String, CaseIterable {
        /// "This app has already run under the current team prefix." After an app transfer the
        /// old marker is unreadable and the first launch of the new build finds none — that
        /// launch is the transfer moment the migration analytics are about.
        case team = "teamMarker"
        /// A cross-team keychain import succeeded; the outcome event is still to be sent.
        case migrationSucceededPending = "usMigrationSucceededPending"
        /// 407196 has been reported once on this device.
        case sessionLostReported = "usSessionLostReported"

        // Computed rather than stored: a `[CFString: Any]` is not Sendable under strict concurrency.
        var query: [CFString: Any] {
            [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: "mega.ios.migration",
                kSecAttrAccount: rawValue
            ]
        }
    }

    private static func markerStatus(_ marker: MigrationMarker) -> OSStatus {
        var query = marker.query
        query[kSecReturnAttributes] = true
        var result: AnyObject?
        return SecItemCopyMatching(query as CFDictionary, &result)
    }

    /// Adds the marker; an existing one is left untouched.
    private static func setMarker(_ marker: MigrationMarker) {
        var item = marker.query
        item[kSecValueData] = Data([1])
        item[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(item as CFDictionary, nil)
    }

    private static func clearMarker(_ marker: MigrationMarker) {
        SecItemDelete(marker.query as CFDictionary)
    }

    /// `errSecSuccess`: seen this team before. `errSecItemNotFound`: first launch under this
    /// team. Anything else (e.g. keychain not yet unlocked): unknown — do not treat as a transfer.
    static func teamMarkerStatus() -> OSStatus {
        markerStatus(.team)
    }

    /// Records the current team prefix.
    static func writeTeamMarker() {
        setMarker(.team)
    }

    /// QA only: forget every marker so the next launch is treated as a cross-team first launch
    /// and all migration events may fire again.
    static func resetMigrationMarkers() {
        MigrationMarker.allCases.forEach(clearMarker)
    }

    /// Records that a cross-team keychain import succeeded on this launch.
    ///
    /// The analytics event is intentionally not sent here. `importKMTransferFile()` runs before
    /// `didFinishLaunching`; the `fastLoginWithSession` that follows goes through
    /// `performRequest_login`, which calls `locallogout()` and clears every SDK command still
    /// queued — a `sendEvent` issued now would be dropped. The flag is persisted so the event
    /// also survives the app being killed before the login completes, and it is kept in the
    /// keychain so a rejected session (`ESID` → `Helper.logout`) cannot wipe it before the
    /// user's credential login reports it as `restoredSessionRejected`.
    static func markMigrationSucceededPending() {
        setMarker(.migrationSucceededPending)
    }

    /// First launch after a (re)install: the keychain outlived the app, but whatever import
    /// happened before the uninstall has no outcome left to report.
    static func clearMigrationSucceededPending() {
        clearMarker(.migrationSucceededPending)
    }

    /// Call once a login (fast or credential) has finished, i.e. after `performRequest_login`
    /// ran its `locallogout`, so commands queued from here on are delivered.
    ///
    /// - `isFirstLogin == false`: the restored session logged in → migration succeeded.
    /// - `isFirstLogin == true`: the restored session was rejected and the user had to enter
    ///   credentials → counted as a migration failure.
    static func didCompleteLogin(isFirstLogin: Bool) {
        guard markerStatus(.migrationSucceededPending) == errSecSuccess else { return }
        clearMarker(.migrationSucceededPending)

        if isFirstLogin {
            DIContainer.tracker.trackAnalyticsEvent(
                with: IOSKMTransferUSMigrationFailedEvent(reason: "restoredSessionRejected")
            )
        } else {
            DIContainer.tracker.trackAnalyticsEvent(with: IOSKMTransferUSMigrationSucceededEvent())
        }
    }

    /// One-shot guard for 407196. Backed by the keychain so a logout in between launches
    /// cannot re-arm it.
    static var hasReportedSessionLost: Bool {
        markerStatus(.sessionLostReported) == errSecSuccess
    }

    static func markSessionLostReported() {
        setMarker(.sessionLostReported)
    }
}
