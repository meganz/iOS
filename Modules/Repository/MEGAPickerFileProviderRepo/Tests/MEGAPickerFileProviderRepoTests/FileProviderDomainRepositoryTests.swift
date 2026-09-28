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

        let sut = FileProviderDomainRepository(builtInPlugInsURL: plugInsURL)

        #expect(sut.isReplicatedExtensionEnabled == expected)
    }

    @Test
    func isReplicatedExtensionEnabled_whenPrincipalClassIsMissing_returnsFalse() throws {
        let plugInsURL = try makePlugInsDirectory(extensionAttributes: [:])
        defer { try? FileManager.default.removeItem(at: plugInsURL) }

        let sut = FileProviderDomainRepository(builtInPlugInsURL: plugInsURL)

        #expect(sut.isReplicatedExtensionEnabled == false)
    }

    @Test
    func isReplicatedExtensionEnabled_whenExtensionIsNotEmbedded_returnsFalse() {
        let plugInsURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)

        let sut = FileProviderDomainRepository(builtInPlugInsURL: plugInsURL)

        #expect(sut.isReplicatedExtensionEnabled == false)
    }

    @Test
    func isReplicatedExtensionEnabled_whenAppHasNoPlugIns_returnsFalse() {
        let sut = FileProviderDomainRepository(builtInPlugInsURL: nil)

        #expect(sut.isReplicatedExtensionEnabled == false)
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
