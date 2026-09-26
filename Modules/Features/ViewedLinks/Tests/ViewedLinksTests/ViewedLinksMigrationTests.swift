import Foundation
import SwiftData
import Testing
@testable import ViewedLinks

@Suite("ViewedLinks lightweight migration", .serialized)
struct ViewedLinksMigrationTests {
    /// A simulated "next" schema that adds one optional attribute to the version-1 model.
    /// Adding an optional (or defaulted) attribute is inferable, so it migrates lightweight.
    fileprivate enum ProbeSchemaV2: VersionedSchema {
        static let versionIdentifier = Schema.Version(2, 0, 0)
        static var models: [any PersistentModel.Type] { [Self.ViewedLinkModel.self] }

        @Model
        final class ViewedLinkModel {
            var handle: Int64
            var linkURL: String
            var name: String
            var isFolder: Bool
            var lastAccessed: Date
            var newAttribute: String?

            init(handle: Int64, linkURL: String, name: String, isFolder: Bool, lastAccessed: Date, newAttribute: String? = nil) {
                self.handle = handle
                self.linkURL = linkURL
                self.name = name
                self.isFolder = isFolder
                self.lastAccessed = lastAccessed
                self.newAttribute = newAttribute
            }
        }
    }

    private enum ProbeMigrationPlan: SchemaMigrationPlan {
        static var schemas: [any VersionedSchema.Type] { [ViewedLinksSchemaV1.self, ProbeSchemaV2.self] }
        static var stages: [MigrationStage] {
            [.lightweight(fromVersion: ViewedLinksSchemaV1.self, toVersion: ProbeSchemaV2.self)]
        }
    }

    /// A simulated "next" schema that adds a non-optional attribute with no default.
    /// Existing rows cannot be filled, so lightweight migration is impossible.
    fileprivate enum ProbeSchemaV2Invalid: VersionedSchema {
        static let versionIdentifier = Schema.Version(2, 0, 0)
        static var models: [any PersistentModel.Type] { [Self.ViewedLinkModel.self] }

        @Model
        final class ViewedLinkModel {
            var handle: Int64
            var linkURL: String
            var name: String
            var isFolder: Bool
            var lastAccessed: Date
            var newAttribute: String

            init(handle: Int64, linkURL: String, name: String, isFolder: Bool, lastAccessed: Date, newAttribute: String) {
                self.handle = handle
                self.linkURL = linkURL
                self.name = name
                self.isFolder = isFolder
                self.lastAccessed = lastAccessed
                self.newAttribute = newAttribute
            }
        }
    }

    private enum ProbeInvalidMigrationPlan: SchemaMigrationPlan {
        static var schemas: [any VersionedSchema.Type] { [ViewedLinksSchemaV1.self, ProbeSchemaV2Invalid.self] }
        static var stages: [MigrationStage] {
            [.lightweight(fromVersion: ViewedLinksSchemaV1.self, toVersion: ProbeSchemaV2Invalid.self)]
        }
    }

    private func seedVersion1Store(at url: URL) async throws {
        let store = ViewedLinksStore(storeURL: url)
        let link = ViewedLinkEntity(
            handle: 7,
            linkURL: try #require(URL(string: "https://mega.nz/file/7#key")),
            name: "a.pdf",
            isFolder: false,
            hasThumbnail: false,
            lastAccessed: Date(timeIntervalSince1970: 0)
        )
        try await store.record(link)
    }

    @Test("a version-1 store lightweight-migrates to a schema that adds an optional attribute")
    func lightweightMigrationAddsOptionalAttribute() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "viewedlinks-migration-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "ViewedLinks.store")

        try await seedVersion1Store(at: url)

        let container = try ModelContainer(
            for: Schema(versionedSchema: ProbeSchemaV2.self),
            migrationPlan: ProbeMigrationPlan.self,
            configurations: ModelConfiguration(url: url, cloudKitDatabase: .none)
        )
        let context = ModelContext(container)
        let rows = try context.fetch(FetchDescriptor<ProbeSchemaV2.ViewedLinkModel>())

        #expect(rows.count == 1)
        #expect(rows.first?.handle == 7)
        #expect(rows.first?.name == "a.pdf")
        #expect(rows.first?.newAttribute == nil)
    }

    @Test("a store reopened at the same schema version preserves its rows")
    func reopenSameVersionPreservesData() async throws {
        let url = try makeTemporaryStoreURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        try await seedVersion1Store(at: url)

        let store = ViewedLinksStore(storeURL: url)
        let all = try await store.viewedLinks(sortedBy: .name, ascending: true)

        #expect(all.map(\.handle) == [7])
        #expect(all.first?.name == "a.pdf")
    }

    @Test("adding a non-optional attribute without a default is refused and leaves the store intact")
    func nonOptionalWithoutDefaultFailsMigration() async throws {
        let url = try makeTemporaryStoreURL()
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        try await seedVersion1Store(at: url)

        // Build the schema up front so a schema-construction failure cannot masquerade as the
        // migration failure under test.
        let invalidSchema = Schema(versionedSchema: ProbeSchemaV2Invalid.self)
        #expect(throws: (any Error).self) {
            _ = try ModelContainer(
                for: invalidSchema,
                migrationPlan: ProbeInvalidMigrationPlan.self,
                configurations: ModelConfiguration(url: url, cloudKitDatabase: .none)
            )
        }

        // After migration error, the original store should still be left intact.
        let survivor = try ModelContainer(
            for: Schema(versionedSchema: ViewedLinksSchemaV1.self),
            configurations: ModelConfiguration(url: url, cloudKitDatabase: .none)
        )
        let rows = try ModelContext(survivor).fetch(FetchDescriptor<ViewedLinkModel>())

        #expect(rows.count == 1)
        #expect(rows.first?.handle == 7)
    }

    private func makeTemporaryStoreURL() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "viewedlinks-migration-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appending(path: "ViewedLinks.store")
    }
}
