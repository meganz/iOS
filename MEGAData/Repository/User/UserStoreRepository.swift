import MEGADomain

struct UserStoreRepository: UserStoreRepositoryProtocol {
    static var newRepo: UserStoreRepository {
        UserStoreRepository(store: MEGAStore.shareInstance())
    }
    
    private let store: MEGAStore
    
    init(store: MEGAStore) {
        self.store = store
    }
    
    func getDisplayName(forUserHandle handle: UInt64) -> String? {
        fetchUser(withHandle: handle)?.displayName
    }
    
    func displayName(forUserHandle handle: UInt64) async -> String? {
        await withCheckedContinuation { continuation in
            guard let context = store.stack.newBackgroundContext() else {
                continuation.resume(returning: nil)
                return
            }
            context.performAndWait {
                let displayName = store.fetchUser(withUserHandle: handle, context: context)?.displayName
                continuation.resume(returning: displayName)
            }
        }
    }
    
    func userDisplayName(forEmail email: String) -> String? {
        fetchUser(withEmail: email)?.displayName
    }
    
    func userFirstName(withHandle handle: UInt64) -> String? {
        fetchUser(withHandle: handle)?.firstname
    }
    
    func userLastName(withHandle handle: UInt64) -> String? {
        fetchUser(withHandle: handle)?.lastname
    }
    
    // MARK: - Private
    
    private func fetchUser(withHandle handle: UInt64) -> MOUser? {
        store.fetchUser(withUserHandle: handle)
    }
    
    private func fetchUser(withEmail email: String) -> MOUser? {
        store.fetchUser(withEmail: email)
    }
}
