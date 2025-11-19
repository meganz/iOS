import Contacts

public protocol DeviceContactsRepositoryProtocol {
    func fetchContacts() -> [CNContact]
}

struct DeviceContactsRepository: DeviceContactsRepositoryProtocol {
    func fetchContacts() -> [CNContact] {
        let store = CNContactStore()
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
            assertionFailure("[DeviceContactsRepository] Unable to fetch contacts")
        }
        
        return contacts
    }
}
