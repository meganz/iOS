

struct UserStoreRepository: UserStoreRepositoryProtocol {
    private let store: MEGAStore
    
    init(store: MEGAStore) {
        self.store = store
    }
    
    func getDisplayName(forUserHandle handle: UInt64) -> String? {
        fetchUser(withHandle: handle)?.displayName
    }
    
    private func fetchUser(withHandle handle: UInt64) -> MOUser? {
        store.fetchUser(withUserHandle: handle)
    }
}
