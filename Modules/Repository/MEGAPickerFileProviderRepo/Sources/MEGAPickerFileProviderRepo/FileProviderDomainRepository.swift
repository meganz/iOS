import FileProvider
import Foundation
import MEGAPickerFileProviderDomain

public struct FileProviderDomainRepository: FileProviderDomainRepositoryProtocol {
    public static var newRepo: FileProviderDomainRepository {
        FileProviderDomainRepository(builtInPlugInsURL: Bundle.main.builtInPlugInsURL, syncDirectoryURL: FileProviderSyncDirectory.url)
    }

    private let builtInPlugInsURL: URL?
    private let syncDirectoryURL: URL

    /// - Parameters:
    ///   - builtInPlugInsURL: The app's `PlugIns` directory, where the File Provider extension is embedded.
    ///   - syncDirectoryURL: Where the extension keeps its sync data.
    public init(builtInPlugInsURL: URL?, syncDirectoryURL: URL) {
        self.builtInPlugInsURL = builtInPlugInsURL
        self.syncDirectoryURL = syncDirectoryURL
    }

    /// The extension's principal class is set by the `MEGA_FILE_PROVIDER_PRINCIPAL_CLASS` build setting, so the
    /// embedded extension is the single source of truth: the app can never manage domains for an extension
    /// that was not switched with it.
    public var isReplicatedExtensionEnabled: Bool {
        guard let infoPlistURL = builtInPlugInsURL?.appendingPathComponent("MEGAPickerFileProvider.appex/Info.plist"),
              let infoPlist = NSDictionary(contentsOf: infoPlistURL),
              let extensionAttributes = infoPlist["NSExtension"] as? [String: Any],
              let principalClass = extensionAttributes["NSExtensionPrincipalClass"] as? String else {
            return false
        }
        // The value is prefixed with the extension's module name, e.g. `MEGAPickerFileProvider.FileProviderExtension`.
        return principalClass.hasSuffix(".ReplicatedFileProviderExtension")
    }

    public func addDomain() async throws {
        // Logout removes the domain, which drops the previous account's cached items before the next account logs in.
        try await NSFileProviderManager.add(.mega)
    }

    public func removeAllDomains() async throws {
        try await NSFileProviderManager.removeAllDomains()
    }

    public func removeSyncData() throws {
        guard FileManager.default.fileExists(atPath: syncDirectoryURL.path) else {
            return
        }
        try FileManager.default.removeItem(at: syncDirectoryURL)
    }
}
