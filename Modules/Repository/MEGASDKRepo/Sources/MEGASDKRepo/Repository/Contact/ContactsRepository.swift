import MEGADomain
import MEGAMacro
import MEGASdk

@newRepo(MEGASdk.sharedSdk)
public struct ContactsRepository: ContactsRepositoryProtocol {
    public func contact(forUserHandle handle: HandleEntity) -> UserEntity? {
        visibleContacts().first(where: { $0.handle == handle })
    }
    
    // MARK: - Private
    private func visibleContacts() -> [UserEntity] {
        sdk.contacts().toUserEntities().filter { $0.visibility == .visible }
    }
}
