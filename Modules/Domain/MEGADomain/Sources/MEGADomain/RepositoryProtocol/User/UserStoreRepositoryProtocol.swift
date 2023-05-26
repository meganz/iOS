
public protocol UserStoreRepositoryProtocol: RepositoryProtocol, Sendable {
    func getDisplayName(forUserHandle handle: UInt64) -> String?
    func displayName(forUserHandle handle: HandleEntity) async -> String?
}
