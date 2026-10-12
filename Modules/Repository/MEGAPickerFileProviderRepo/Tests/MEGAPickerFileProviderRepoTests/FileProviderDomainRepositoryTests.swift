import Foundation
import MEGAPickerFileProviderRepo
import Testing

struct FileProviderDomainRepositoryTests {
    @Test(arguments: [
        ("MEGAPickerFileProvider.ReplicatedFileProviderExtension", true),
        ("MEGAPickerFileProvider.FileProviderExtension", false)
    ])
    func isReplicatedExtensionEnabled_readsEmbeddedExtensionPrincipalClass(principalClass: String, expected: Bool) throws {
        let plugInsURL = try makePlugInsDirectory(extensionAttributes: ["NSExtensionPrincipalClass": principalClass])
        defer { try? FileManager.default.removeItem(at: plugInsURL) }

        let sut = makeSUT(builtInPlugInsURL: plugInsURL)

        #expect(sut.isReplicatedExtensionEnabled == expected)
    }

    @Test
    func isReplicatedExtensionEnabled_whenPrincipalClassIsMissing_returnsFalse() throws {
        let plugInsURL = try makePlugInsDirectory(extensionAttributes: [:])
        defer { try? FileManager.default.removeItem(at: plugInsURL) }

        let sut = makeSUT(builtInPlugInsURL: plugInsURL)

        #expect(sut.isReplicatedExtensionEnabled == false)
    }

    @Test
    func isReplicatedExtensionEnabled_whenExtensionIsNotEmbedded_returnsFalse() {
        let plugInsURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        let sut = makeSUT(builtInPlugInsURL: plugInsURL)

        #expect(sut.isReplicatedExtensionEnabled == false)
    }

    @Test
    func isReplicatedExtensionEnabled_whenAppHasNoPlugIns_returnsFalse() {
        let sut = makeSUT(builtInPlugInsURL: nil)

        #expect(sut.isReplicatedExtensionEnabled == false)
    }

    @Test
    func removeSyncData_deletesTheSyncDirectory() throws {
        let syncDirectoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let snapshotsURL = syncDirectoryURL.appendingPathComponent("Snapshots", isDirectory: true)
        try FileManager.default.createDirectory(at: snapshotsURL, withIntermediateDirectories: true)
        try Data("snapshot".utf8).write(to: snapshotsURL.appendingPathComponent("root.snapshot"))
        defer { try? FileManager.default.removeItem(at: syncDirectoryURL) }
        let sut = makeSUT(builtInPlugInsURL: nil, syncDirectoryURL: syncDirectoryURL)

        try sut.removeSyncData()

        #expect(FileManager.default.fileExists(atPath: syncDirectoryURL.path) == false)
    }

    @Test
    func removeSyncData_withoutSyncDirectory_doesNotThrow() throws {
        let syncDirectoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let sut = makeSUT(builtInPlugInsURL: nil, syncDirectoryURL: syncDirectoryURL)

        try sut.removeSyncData()
    }

    private func makeSUT(
        builtInPlugInsURL: URL?,
        syncDirectoryURL: URL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    ) -> FileProviderDomainRepository {
        FileProviderDomainRepository(builtInPlugInsURL: builtInPlugInsURL, syncDirectoryURL: syncDirectoryURL)
    }

    private func makePlugInsDirectory(extensionAttributes: [String: String]) throws -> URL {
        let plugInsURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let extensionURL = plugInsURL.appendingPathComponent("MEGAPickerFileProvider.appex")
        try FileManager.default.createDirectory(at: extensionURL, withIntermediateDirectories: true)
        let infoPlist = try PropertyListSerialization.data(
            fromPropertyList: ["NSExtension": extensionAttributes],
            format: .xml,
            options: 0
        )
        try infoPlist.write(to: extensionURL.appendingPathComponent("Info.plist"))
        return plugInsURL
    }
}
