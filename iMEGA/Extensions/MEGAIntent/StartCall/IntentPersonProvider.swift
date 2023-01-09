import Contacts
import Intents

struct IntentPersonProvider {
    private let contactStore = CNContactStore()

    func personsInContacts(_ person: INPerson) -> [INPerson] {
        var contacts: [CNContact] = []

        let keys: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor
        ]

        do {
            try contactStore.enumerateContacts(with: CNContactFetchRequest(keysToFetch: keys)) { contact, _ -> Void in
                guard !contact.emailAddresses.isEmpty else { return }
                
                let personDisplayName = person.displayName.lowercased()
                let contactFirstName = contact.givenName.lowercased()
                let contactLastName = contact.familyName.lowercased()

                if personDisplayName.lowercased().contains(contactFirstName.lowercased()) ||
                    personDisplayName.lowercased().contains(contactLastName.lowercased()) {
                    contacts.append(contact)
                }
            }
        } catch {
            assertionFailure("Unable to fetch contacts.")
        }
        
        let filteredContacts = contacts.filter {
            person.displayName.lowercased().contains($0.givenName.lowercased()) && person.displayName.lowercased().contains($0.familyName.lowercased())
        }
        
        if filteredContacts.isNotEmpty {
            contacts = filteredContacts
        }

        let persons = contacts.persons(withDisplayName: person.displayName)

        return persons.removeDuplicatesWhileKeepingTheOriginalOrder()
    }
}
