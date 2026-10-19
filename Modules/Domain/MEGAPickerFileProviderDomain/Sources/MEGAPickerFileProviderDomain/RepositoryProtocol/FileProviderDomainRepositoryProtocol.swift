import FileProvider
import MEGADomain

public protocol FileProviderDomainRepositoryProtocol: RepositoryProtocol, Sendable {
    /// Whether the embedded File Provider extension is the `NSFileProviderReplicatedExtension` one, which only
    /// shows up in Files once the app has registered a domain for it.
    var isReplicatedExtensionEnabled: Bool { get }
    func addDomain() async throws
    func removeAllDomains() async throws
    /// Tells the system to retry the items of the domain that it stopped retrying after they failed with `error`.
    func signalErrorResolved(_ error: NSFileProviderError) async throws
    /// Deletes the snapshots and the change queue the extension keeps for the domain.
    func removeSyncData() async throws
}
