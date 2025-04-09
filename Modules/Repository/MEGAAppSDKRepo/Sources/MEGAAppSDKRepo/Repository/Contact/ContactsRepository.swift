import MEGADomain
import MEGASdk

public struct ContactsRepository: ContactsRepositoryProtocol {
    private let sdk: MEGASdk
    
    public static var newRepo: ContactsRepository {
        ContactsRepository(sdk: MEGASdk.sharedSdk)
    }
    
    public init(sdk: MEGASdk) {
        self.sdk = sdk
    }
    
    public func contact(forUserHandle handle: HandleEntity) -> UserEntity? {
        visibleContacts().first(where: { $0.handle == handle })
    }
    
    public var isContactVerificationWarningEnabled: Bool {
        sdk.isContactVerificationWarningEnabled
    }
    
    // MARK: - Private
    private func visibleContacts() -> [UserEntity] {
        sdk.contacts().toUserEntities().filter { $0.visibility == .visible }
    }
    
}
