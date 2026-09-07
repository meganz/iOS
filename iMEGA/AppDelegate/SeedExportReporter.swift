import FirebaseCrashlytics
import Foundation
import MEGAAppSDKRepo
import MEGADomain
import MEGARepo
import MEGASdk
import MEGASwift

/// Classifies the files `AppDelegate.copyDatabasesForExtensions` exports into the App Group
/// `GroupSupport` folder, so that only the node (file tree) database is reported when a copy fails.
enum SeedExportDatabase {
    private static let prefix = "megaclient_statecache"
    private static let suffix = ".db"

    /// `Base64::btoa(SIDLEN - 16)`, 27 bytes. Every SDK database shares the
    /// `megaclient_statecache<version>_<name>.db` shape, so this length is what separates the node
    /// database from its neighbours — a folder link's is 8, a sync state cache's 32. Don't widen it.
    private static let sessionHandleLength = 36

    /// The statecache version of `filename` when it is the node (file tree) database, `nil` for
    /// every other file. Both ends are anchored: the `.db` suffix rejects the `-journal` / `-wal` /
    /// `-shm` sidecars, the handle length the rest.
    static func treeDatabaseVersion(of filename: String) -> Int? {
        guard filename.hasPrefix(prefix), filename.hasSuffix(suffix) else { return nil }

        let body = filename.dropFirst(prefix.count).dropLast(suffix.count)
        guard let separator = body.firstIndex(of: "_") else { return nil }

        let version = body[body.startIndex..<separator]
        guard !version.isEmpty, version.allSatisfy(isASCIIDigit) else { return nil }

        let handle = body[body.index(after: separator)...]
        guard handle.count == sessionHandleLength, handle.allSatisfy(isBase64URLCharacter) else { return nil }

        return Int(version)
    }

    /// Whether the export should report that there was no node database at all to copy.
    ///
    /// Any session's satisfies this, deliberately unlike `groupSeedState(forSeedNamed:in:…)`: that
    /// one is handed the name of the file being copied, whereas nothing here has a name to compare
    /// against. Building one would mean reimplementing the SDK's naming — `Base64::btoa` over bytes
    /// 32..<59 of the decoded session, which is not sliceable out of the session string, plus a
    /// `DB_VERSION` the bindings do not expose — and if either ever changed this would fire on
    /// every export. It would also mostly catch a benign window: a fresh password login opens the
    /// database in `fetchnodes`, not in `login`, so it is legitimately absent for a while, which is
    /// what `has_root_node` marks on the report.
    ///
    /// Gated on a stored session so a fresh install does not report before login. `hasSession` is
    /// an autoclosure to keep the keychain out of the common path, where a database is present.
    static func shouldReportMissingTreeDatabase(applicationSupportContent: [String],
                                                hasSession: @autoclosure () -> Bool) -> Bool {
        !applicationSupportContent.contains { treeDatabaseVersion(of: $0) != nil } && hasSession()
    }

    /// The node databases in a `GroupSupport` listing, whichever session or statecache version they
    /// belong to.
    static func nodeDatabases(in groupSupportContent: [String]) -> [String] {
        groupSupportContent.filter { treeDatabaseVersion(of: $0) != nil }
    }

    /// What `GroupSupport` holds for `filename` — the node database whose copy just failed.
    ///
    /// The name is matched exactly, not by statecache version: the handle comes from the session,
    /// so a fresh login changes it and a database from an earlier one is not a seed the extensions
    /// can open. Presence alone is not enough either — `copyItemAtPath:toPath:` is not atomic and
    /// need not unlink the destination when it fails part-way, so a truncated file can be sitting
    /// under this very name. Only a byte count matching the source counts as a seed.
    ///
    /// A mismatch is evidence, not proof: the source is still being written, and a failed pre-copy
    /// remove would leave an older but valid seed. `copy_error_code` and both sizes are reported so
    /// triage can tell which.
    static func groupSeedState(forSeedNamed filename: String,
                               in groupSupportContent: [String],
                               destinationSize: Int?,
                               sourceSize: Int?) -> SeedExportGroupState {
        let nodeDatabases = nodeDatabases(in: groupSupportContent)

        guard nodeDatabases.contains(filename) else {
            return nodeDatabases.isEmpty ? .empty : .foreignSeedsOnly
        }

        guard let destinationSize, let sourceSize, destinationSize == sourceSize else {
            return .seedTruncated
        }
        return .seedIntact
    }

    /// The version is matched digit by digit rather than handed straight to `Int(_:)`, which also
    /// accepts a leading `+` or `-` and would let `megaclient_statecache-14_<handle>.db` through.
    private static func isASCIIDigit(_ character: Character) -> Bool {
        character.isASCII && character.isNumber
    }

    private static func isBase64URLCharacter(_ character: Character) -> Bool {
        character.isASCII && (character.isLetter || character.isNumber || character == "-" || character == "_")
    }
}

/// What `GroupSupport` still holds for this session after a failed node database copy.
enum SeedExportGroupState: String {
    /// This session's seed is there and matches the source's byte count.
    case seedIntact = "seed_intact"
    /// This session's seed is there but its byte count does not match the source.
    case seedTruncated = "seed_truncated"
    /// No node database at all.
    case empty
    /// Node databases are there, but all from earlier logins — `GroupSupport` is never pruned.
    case foreignSeedsOnly = "foreign_seeds_only"
}

/// A domain of our own, so a real failure is not titled `NSPOSIXErrorDomain` code 2 like the
/// journal noise the export produces constantly. Separation in Crashlytics comes from the call
/// site, not from these values — see `SeedExportReporter.record(_:userInfo:)`.
enum SeedExportFailure: Int {
    static let domain = "MEGASeedExportErrorDomain"

    /// No usable seed left. The export removes the destination before copying, so a failure here
    /// also took out the previous good seed.
    case seedLost = 1
    /// A seed of the source's size is still in place. Not expected — with `EEXIST`, the pre-copy
    /// remove is what failed.
    case seedStale = 2
    /// No node database in Application Support while a session is stored.
    case treeDatabaseMissing = 3
    /// A partially written seed is in place. Ranked above `seedLost`: no seed costs the extensions
    /// a full fetch, a partial one gets opened as a state cache.
    case seedTruncated = 4

    var message: String {
        switch self {
        case .seedLost: "file tree DB copy failed, no usable seed left in GroupSupport"
        case .seedStale: "file tree DB copy failed, a seed of the source's size is still in place"
        case .treeDatabaseMissing: "no file tree DB in Application Support"
        case .seedTruncated: "file tree DB copy failed part-way, GroupSupport holds a partial seed"
        }
    }
}

/// Reporting for the seed export in `AppDelegate.copyDatabasesForExtensions`.
///
/// Not an `AppDelegate` extension on purpose: `UIResponder` is `@MainActor`, so every member of the
/// delegate inherits that isolation, and the export runs on a global queue — calling in from there
/// trips the executor assertion.
@objc final class SeedExportReporter: NSObject {

    /// Reports a failed copy of the node (file tree) database, and drops every other file.
    ///
    /// The error code is not filtered: `ENOENT` here is a real event (logout, session change,
    /// version migration), unlike on the files around it.
    @objc(reportCopyFailureWithError:filename:sourcePath:groupSupportPath:)
    static func reportCopyFailure(error: (any Error)?,
                                  filename: String,
                                  sourcePath: String,
                                  groupSupportPath: String) {
        guard let version = SeedExportDatabase.treeDatabaseVersion(of: filename) else { return }

        let fileManager = FileManager.default
        let groupSupportContent = (try? fileManager.contentsOfDirectory(atPath: groupSupportPath)) ?? []
        let destinationPath = (groupSupportPath as NSString).appendingPathComponent(filename)
        let sourceSize = fileSize(atPath: sourcePath)
        let destinationSize = fileSize(atPath: destinationPath)
        let groupState = SeedExportDatabase.groupSeedState(forSeedNamed: filename,
                                                          in: groupSupportContent,
                                                          destinationSize: destinationSize,
                                                          sourceSize: sourceSize)
        var userInfo: [String: Any] = [
            "db_version": version,
            "group_seed_state": groupState.rawValue,
            // Orphans accumulate because nothing prunes GroupSupport; the count says how far.
            "group_node_db_count": SeedExportDatabase.nodeDatabases(in: groupSupportContent).count
        ]

        if let error = error as NSError? {
            userInfo["copy_error_domain"] = error.domain
            userInfo["copy_error_code"] = error.code

            if let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError {
                userInfo["underlying_error_domain"] = underlyingError.domain
                userInfo["underlying_error_code"] = underlyingError.code
            }
        }

        if let sourceSize {
            userInfo["source_size"] = sourceSize
        }

        if let destinationSize {
            userInfo["destination_size"] = destinationSize
        }

        if let freeSpace = try? fileManager.attributesOfFileSystem(forPath: groupSupportPath)[.systemFreeSize] {
            userInfo["group_free_space"] = freeSpace
        }

        let failure: SeedExportFailure = switch groupState {
        case .seedIntact: .seedStale
        case .seedTruncated: .seedTruncated
        case .empty, .foreignSeedsOnly: .seedLost
        }
        record(failure, userInfo: userInfo)
    }

    /// Reports that no node (file tree) database existed when the export ran.
    @objc(reportMissingTreeDatabaseIfNeededWithApplicationSupportContent:)
    static func reportMissingTreeDatabaseIfNeeded(applicationSupportContent: [String]) {
        guard !reportedFailures.wrappedValue.contains(.treeDatabaseMissing),
              SeedExportDatabase.shouldReportMissingTreeDatabase(
                  applicationSupportContent: applicationSupportContent,
                  hasSession: CredentialUseCase(repo: CredentialRepository.newRepo).hasSession()
              )
        else { return }

        record(.treeDatabaseMissing, userInfo: [
            "statecache_file_count": applicationSupportContent.filter { $0.contains("megaclient_statecache") }.count,
            "application_support_file_count": applicationSupportContent.count,
            "has_root_node": MEGASdk.shared.rootNode != nil
        ])
    }

    // MARK: - Private

    /// The export reruns for every new chat room, onto a concurrent queue, so the runs also
    /// overlap. One report of each kind per launch is all triage needs; `record` is the authority,
    /// callers may read this first to skip the work that would feed a duplicate.
    private static let reportedFailures = Atomic<Set<SeedExportFailure>>(wrappedValue: [])

    private static func fileSize(atPath path: String) -> Int? {
        (try? FileManager.default.attributesOfItem(atPath: path))?[.size] as? Int
    }

    private static func record(_ failure: SeedExportFailure, userInfo: [String: Any]) {
        var isFirstThisLaunch = false
        reportedFailures.mutate { isFirstThisLaunch = $0.insert(failure).inserted }
        guard isFirstThisLaunch else { return }

        CrashlyticsLogger.log(category: .appLifecycle, "Extensions DB export: \(failure.message)")

        // `FIRCLSNonFatalError` snapshots `NSThread.callStackReturnAddresses` where `recordError:`
        // is called, and the header describes non-fatals as grouped like crashes — so the four
        // kinds need four call sites. Routing them through one helper would hand Crashlytics the
        // same frame every time and risk collapsing them into a single issue, which is the whole
        // thing this reporting set out to avoid. `@inline(never)` keeps the frames distinct in
        // release builds.
        switch failure {
        case .seedLost: recordSeedLost(userInfo)
        case .seedStale: recordSeedStale(userInfo)
        case .treeDatabaseMissing: recordTreeDatabaseMissing(userInfo)
        case .seedTruncated: recordSeedTruncated(userInfo)
        }
    }

    @inline(never)
    private static func recordSeedLost(_ userInfo: [String: Any]) {
        Crashlytics.crashlytics().record(error: error(for: .seedLost), userInfo: userInfo)
    }

    @inline(never)
    private static func recordSeedStale(_ userInfo: [String: Any]) {
        Crashlytics.crashlytics().record(error: error(for: .seedStale), userInfo: userInfo)
    }

    @inline(never)
    private static func recordTreeDatabaseMissing(_ userInfo: [String: Any]) {
        Crashlytics.crashlytics().record(error: error(for: .treeDatabaseMissing), userInfo: userInfo)
    }

    @inline(never)
    private static func recordSeedTruncated(_ userInfo: [String: Any]) {
        Crashlytics.crashlytics().record(error: error(for: .seedTruncated), userInfo: userInfo)
    }

    private static func error(for failure: SeedExportFailure) -> NSError {
        NSError(domain: SeedExportFailure.domain, code: failure.rawValue)
    }
}
