import Contacts
import Intents
import MEGASwift

protocol IntentPersonUseCaseProtocol {
    func personsInContacts(matching person: INPerson) -> [INPerson]
}

public struct IntentPersonUseCase: IntentPersonUseCaseProtocol {
    private let repository: any DeviceContactsRepositoryProtocol
    
    public init(
        repository: some DeviceContactsRepositoryProtocol
    ) {
        self.repository = repository
    }
    
    public init() {
        self.init(repository: DeviceContactsRepository())
    }

    public func personsInContacts(matching person: INPerson) -> [INPerson] {
        let contacts = fetchContacts()
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
    
    // MARK: - Private
    
    private func fetchContacts() -> [CNContact] {
        repository.fetchContacts()
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

private extension [CNContact] {
    func persons(withDisplayName displayName: String) -> [INPerson] {
        let persons = self.flatMap { contact -> [INPerson] in
            let persons = contact.emailAddresses.compactMap {
                let personHandle = INPersonHandle(value: $0.value as String, type: .emailAddress)
                return INPerson(
                    personHandle: personHandle,
                    nameComponents: nil,
                    displayName: displayName,
                    image: nil, contactIdentifier: nil, customIdentifier: nil
                )
            }
            return persons
        }
        return persons
    }
}
