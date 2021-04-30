

protocol UserStoreRepositoryProtocol {
    func getDisplayName(forUserHandle handle: UInt64) -> String?
}
