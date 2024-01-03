public protocol UserStoreRepositoryProtocol: RepositoryProtocol, Sendable {
    func getDisplayName(forUserHandle handle: UInt64) -> String?
    func displayName(forUserHandle handle: HandleEntity) async -> String?
    func userDisplayName(forEmail email: String) -> String?
    func userFirstName(withHandle handle: UInt64) -> String?
    func userLastName(withHandle handle: UInt64) -> String?
}
