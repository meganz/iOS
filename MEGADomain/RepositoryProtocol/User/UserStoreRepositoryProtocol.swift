

protocol UserStoreRepositoryProtocol {
    func getDisplayName(forUserHandle handle: UInt64) -> String?
    func displayName(forUserHandle handle: MEGAHandle) async -> String?
}
