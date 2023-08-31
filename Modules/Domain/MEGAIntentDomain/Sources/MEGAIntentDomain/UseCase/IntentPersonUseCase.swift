import Contacts
import Intents
import MEGADomain

protocol IntentPersonUseCaseProtocol {
    func personsInContacts(matching person: INPerson) -> [INPerson]
}

public struct IntentPersonUseCase: IntentPersonUseCaseProtocol {
    private let repository: any ContactsRepositoryProtocol

    public init(repository: some ContactsRepositoryProtocol) {
        self.repository = repository
    }

    public func personsInContacts(matching person: INPerson) -> [INPerson] {
        let contacts = repository.fetchContacts()
        let personDisplayName = person.displayName.lowercased()

        let initialFilter = contacts.filter { contact in
            guard contact.emailAddresses.isNotEmpty else { return false }

            return personDisplayName.contains(contact.firstName) || personDisplayName.contains(contact.lastName)
        }

        let secondFilter = initialFilter.filter { contact in
            personDisplayName.contains(contact.firstName) && personDisplayName.contains(contact.lastName)
        }

        let filteredContacts = secondFilter.isNotEmpty ? secondFilter : initialFilter

        return filteredContacts
            .persons(withDisplayName: personDisplayName)
            .removeDuplicatesWhileKeepingTheOriginalOrder()
    }
}

private extension CNContact {
    var firstName: String {
        givenName.lowercased()
    }

    var lastName: String {
        familyName.lowercased()
    }
}
