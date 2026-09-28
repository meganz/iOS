import FileProvider
import Foundation
import MEGAPickerFileProviderDomain

public struct FileProviderDomainRepository: FileProviderDomainRepositoryProtocol {
    public static var newRepo: FileProviderDomainRepository {
        FileProviderDomainRepository(builtInPlugInsURL: Bundle.main.builtInPlugInsURL)
    }

    private let builtInPlugInsURL: URL?

    /// - Parameter builtInPlugInsURL: The app's `PlugIns` directory, where the File Provider extension is embedded.
    public init(builtInPlugInsURL: URL?) {
        self.builtInPlugInsURL = builtInPlugInsURL
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
        // One fixed domain whichever account is logged in, so Files only ever shows one MEGA location. Logout
        // removes it, which drops the previous account's cached items before the next account logs in.
        let domain = NSFileProviderDomain(identifier: NSFileProviderDomainIdentifier("mega"), displayName: "MEGA")
        try await NSFileProviderManager.add(domain)
    }

    public func removeAllDomains() async throws {
        try await NSFileProviderManager.removeAllDomains()
    }
}
