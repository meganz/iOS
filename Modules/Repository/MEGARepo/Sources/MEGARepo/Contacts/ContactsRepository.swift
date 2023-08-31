import Contacts
import MEGADomain

public struct ContactsRepository: ContactsRepositoryProtocol {
    public static var newRepo: ContactsRepository {
        ContactsRepository()
    }

    public var isAuthorizedToAccessPhoneContacts: Bool {
        CNContactStore.authorizationStatus(for: .contacts) == .authorized
    }

    private let store = CNContactStore()
    
    public init() {}

    public func fetchContacts() -> [CNContact] {
        var contacts: [CNContact] = []

        let keys: [any CNKeyDescriptor] = [
            CNContactGivenNameKey as (any CNKeyDescriptor),
            CNContactFamilyNameKey as (any CNKeyDescriptor),
            CNContactEmailAddressesKey as (any CNKeyDescriptor)
        ]

        let fetchRequest = CNContactFetchRequest(keysToFetch: keys)

        do {
            try store.enumerateContacts(with: fetchRequest) { contact, _ in
                contacts.append(contact)
            }
        } catch {
            assertionFailure("[ContactsRepository] Unable to fetch contacts")
        }

        return contacts
    }
}
