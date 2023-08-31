import Contacts
import Intents
import MEGADomain
import MEGAIntentDomain
import XCTest

class IntentPersonUseCaseTests: XCTestCase {
    func testPersonsInContacts_whenSecondFilterNotEmpty_shouldReturnSecondFilterResult() {
        let mockContactsRepository = MockContactsRepository(contacts: [
            makeContact(givenName: "John", familyName: "Doe", emailAddresses: ["johndoe@example.com"]),
            makeContact(givenName: "Jane", familyName: "Doe", emailAddresses: ["jane@example.com"])
        ])

        let sut = IntentPersonUseCase(repository: mockContactsRepository)

        let person = makePerson()

        let result = sut.personsInContacts(matching: person)

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first, person)
    }

    func testPersonsInContacts_whenSecondFilterEmpty_shouldReturnFirstFilterResult() {
        let mockContactsRepository = MockContactsRepository(contacts: [
            makeContact(givenName: "John", familyName: "Smith", emailAddresses: ["johnsmith@example.com"]),
            makeContact(givenName: "Jane", familyName: "Doe", emailAddresses: ["janedoe@example.com"])
        ])

        let sut = IntentPersonUseCase(repository: mockContactsRepository)

        let person = makePerson()

        let result = sut.personsInContacts(matching: person)

        XCTAssertEqual(result.count, 2)
    }

    func testPersonsInContacts_whenBothFiltersEmpty_shouldReturnEmpty() {
        let mockContactsRepository = MockContactsRepository(contacts: [
            makeContact(givenName: "Emily", familyName: "Smith", emailAddresses: ["emilysmith@example.com"])
        ])

        let sut = IntentPersonUseCase(repository: mockContactsRepository)

        let person = makePerson()

        let result = sut.personsInContacts(matching: person)

        XCTAssertTrue(result.isEmpty)
    }

    func makeContact(givenName: String, familyName: String, emailAddresses: [String]) -> CNContact {
        let contact = CNMutableContact()
        contact.givenName = givenName
        contact.familyName = familyName
        contact.emailAddresses = emailAddresses.map { CNLabeledValue(label: CNLabelHome, value: $0 as NSString) }
        return contact
    }

    func makePerson() -> INPerson {
        INPerson(
           personHandle: .init(value: "johndoe@example.com", type: .emailAddress),
           nameComponents: nil,
           displayName: "john doe",
           image: nil,
           contactIdentifier: nil,
           customIdentifier: nil
       )
    }
}

private extension IntentPersonUseCaseTests {
    struct MockContactsRepository: ContactsRepositoryProtocol {
        static var newRepo: MockContactsRepository {
            MockContactsRepository(contacts: [])
        }

        var isAuthorizedToAccessPhoneContacts: Bool = true
        let contactsToReturn: [CNContact]

        init(contacts: [CNContact]) {
            self.contactsToReturn = contacts
        }

        func fetchContacts() -> [CNContact] {
            contactsToReturn
        }
    }
}
