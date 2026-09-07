@testable import MEGA
import Testing

/// `AbCdEfGhIjKlMnOpQrStUvWxYz0123456789` throughout is a 36 character handle, the length the SDK
/// derives from the session for the node database.
struct SeedExportDatabaseTests {

    @Test(arguments: [
        ("megaclient_statecache14_AbCdEfGhIjKlMnOpQrStUvWxYz0123456789.db", 14),
        ("megaclient_statecache9_AbCdEfGhIjKlMnOpQrStUvWxYz0123456789.db", 9),
        // The handle alphabet is URL safe base64, so "-" and "_" are valid characters in it.
        ("megaclient_statecache14_-_CdEfGhIjKlMnOpQrStUvWxYz0123456789.db", 14)
    ])
    func nodeDatabaseIsRecognisedWithItsVersion(filename: String, expectedVersion: Int) {
        #expect(SeedExportDatabase.treeDatabaseVersion(of: filename) == expectedVersion)
    }

    @Test(arguments: [
        // SQLite rollback journals — iOS runs without WAL, so these churn constantly.
        "megaclient_statecache14_AbCdEfGhIjKlMnOpQrStUvWxYz0123456789.db-journal",
        "megaclient_statecache14_AbCdEfGhIjKlMnOpQrStUvWxYz0123456789.db-wal",
        "megaclient_statecache14_AbCdEfGhIjKlMnOpQrStUvWxYz0123456789.db-shm",
        // Databases that do not carry the node tree.
        "megaclient_statecache14_prefs.db",
        "megaclient_statecache14_status_AbCdEfGhIjKlMnOpQrStUvWxYz0123456789.db",
        "megaclient_statecache14_transfers_AbCdEfGhIjKlMnOpQrStUvWxYz0123456789.db",
        // Folder link databases, keyed by an 8 character NODEHANDLE.
        "megaclient_statecache14_sLlFURoZ.db",
        "megaclient_statecache14_transfers_sLlFURoZ.db",
        // Chat.
        "karere-AbCdEfGhIjKlMnOpQrStUvWxYz0123456789.db",
        "karere-AbCdEfGhIjKlMnOpQrStUvWxYz0123456789.db-journal",
        // Malformed: no version, no separator, and a handle one character short.
        "megaclient_statecache_AbCdEfGhIjKlMnOpQrStUvWxYz0123456789.db",
        "megaclient_statecache14AbCdEfGhIjKlMnOpQrStUvWxYz0123456789.db",
        "megaclient_statecache14_AbCdEfGhIjKlMnOpQrStUvWxYz012345678.db",
        // A signed version: `Int(_:)` accepts these, the version must not.
        "megaclient_statecache-14_AbCdEfGhIjKlMnOpQrStUvWxYz0123456789.db",
        "megaclient_statecache+14_AbCdEfGhIjKlMnOpQrStUvWxYz0123456789.db",
        // A sync state cache: same shape, 32 characters — the nearest neighbour to keep out.
        "megaclient_statecache14_AbCdEfGhIjKlMnOpQrStUvWxYz012345.db",
        "MEGACD.sqlite"
    ])
    func everyOtherExportedFileIsRejected(filename: String) {
        #expect(SeedExportDatabase.treeDatabaseVersion(of: filename) == nil)
    }

    @Test("A missing node database is reported only while a session is stored", arguments: [true, false])
    func missingNodeDatabaseIsGatedOnTheSession(hasSession: Bool) {
        let contentWithoutNodeDatabase = [
            "megaclient_statecache14_prefs.db",
            "megaclient_statecache14_transfers_AbCdEfGhIjKlMnOpQrStUvWxYz0123456789.db",
            "megaclient_statecache14_AbCdEfGhIjKlMnOpQrStUvWxYz0123456789.db-journal"
        ]

        #expect(SeedExportDatabase.shouldReportMissingTreeDatabase(
            applicationSupportContent: contentWithoutNodeDatabase,
            hasSession: hasSession
        ) == hasSession)
    }

    @Test(arguments: [true, false])
    func presentNodeDatabaseIsNeverReported(hasSession: Bool) {
        #expect(SeedExportDatabase.shouldReportMissingTreeDatabase(
            applicationSupportContent: [
                "megaclient_statecache14_prefs.db",
                "megaclient_statecache14_AbCdEfGhIjKlMnOpQrStUvWxYz0123456789.db"
            ],
            hasSession: hasSession
        ) == false)
    }

    @Test func emptyApplicationSupportIsReportedWithASession() {
        #expect(SeedExportDatabase.shouldReportMissingTreeDatabase(
            applicationSupportContent: [],
            hasSession: true
        ))
    }

    // MARK: - Group seed state

    /// The handle comes from the session, so a different login carries a different one.
    private static let currentSeed = "megaclient_statecache14_AbCdEfGhIjKlMnOpQrStUvWxYz0123456789.db"
    private static let earlierLoginSeed = "megaclient_statecache14_ZzYyXxWwVvUuTtSsRrQqPpOoNnMm01234567.db"

    @Test func seedMatchingTheSourceSizeIsIntact() {
        #expect(SeedExportDatabase.groupSeedState(
            forSeedNamed: Self.currentSeed,
            in: [Self.currentSeed, "megaclient_statecache14_prefs.db"],
            destinationSize: 4_096,
            sourceSize: 4_096
        ) == .seedIntact)
    }

    /// A copy failing part-way need not unlink the destination, so on ENOSPC the bytes it wrote
    /// stay under the seed's own name.
    @Test func seedShorterThanTheSourceIsTruncated() {
        #expect(SeedExportDatabase.groupSeedState(
            forSeedNamed: Self.currentSeed,
            in: [Self.currentSeed],
            destinationSize: 1_024,
            sourceSize: 4_096
        ) == .seedTruncated)
    }

    @Test("An unreadable size on either side is treated as the more severe case",
          arguments: [(nil, 4_096), (4_096, nil), (nil, nil)] as [(Int?, Int?)])
    func seedWithAnUnknownSizeIsTruncated(destinationSize: Int?, sourceSize: Int?) {
        #expect(SeedExportDatabase.groupSeedState(
            forSeedNamed: Self.currentSeed,
            in: [Self.currentSeed],
            destinationSize: destinationSize,
            sourceSize: sourceSize
        ) == .seedTruncated)
    }

    @Test func noNodeDatabaseIsEmpty() {
        #expect(SeedExportDatabase.groupSeedState(
            forSeedNamed: Self.currentSeed,
            in: ["megaclient_statecache14_prefs.db", "MEGACD.sqlite"],
            destinationSize: nil,
            sourceSize: 4_096
        ) == .empty)
    }

    /// Switching account, or just logging in again, leaves the previous login's database behind —
    /// same statecache version, but not one the extensions can open.
    @Test func seedFromAnEarlierLoginIsNotASurvivingSeed() {
        #expect(SeedExportDatabase.groupSeedState(
            forSeedNamed: Self.currentSeed,
            in: [Self.earlierLoginSeed, "megaclient_statecache14_prefs.db"],
            destinationSize: nil,
            sourceSize: 4_096
        ) == .foreignSeedsOnly)
    }

    @Test func seedFromAnEarlierStatecacheVersionIsNotASurvivingSeed() {
        #expect(SeedExportDatabase.groupSeedState(
            forSeedNamed: Self.currentSeed,
            in: ["megaclient_statecache13_AbCdEfGhIjKlMnOpQrStUvWxYz0123456789.db"],
            destinationSize: nil,
            sourceSize: 4_096
        ) == .foreignSeedsOnly)
    }

    @Test func nodeDatabasesExcludeEverythingElse() {
        #expect(SeedExportDatabase.nodeDatabases(in: [
            Self.currentSeed,
            Self.earlierLoginSeed,
            "megaclient_statecache14_prefs.db",
            "megaclient_statecache14_transfers_AbCdEfGhIjKlMnOpQrStUvWxYz0123456789.db",
            "megaclient_statecache14_sLlFURoZ.db",
            "\(Self.currentSeed)-journal",
            "MEGACD.sqlite"
        ]) == [Self.currentSeed, Self.earlierLoginSeed])
    }
}
