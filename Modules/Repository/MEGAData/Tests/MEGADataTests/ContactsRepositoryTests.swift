
import Contacts
import MEGAData
import XCTest

final class ContactsRepositoryTests: XCTestCase {
    func testIsAuthorizedToAccessPhoneContacts() {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        let sut = ContactsRepository()
        if status == .authorized {
            XCTAssertTrue(sut.isAuthorizedToAccessPhoneContacts)
        } else {
            XCTAssertFalse(sut.isAuthorizedToAccessPhoneContacts)
        }
    }
}
