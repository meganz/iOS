import Contacts
import MEGADomain

public struct ContactsRepository: ContactsRepositoryProtocol {
    public var isAuthorizedToAccessPhoneContacts: Bool {
        CNContactStore.authorizationStatus(for: .contacts) == .authorized
    }
    
    public init() {}
}
