import Contacts
import MEGARepo
import XCTest

final class ContactsRepositoryTests: XCTestCase {
    func testIsAuthorizedToAccessPhoneContacts() {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        let sut = DeviceContactsRepository()
        if status == .authorized {
            XCTAssertTrue(sut.isAuthorizedToAccessPhoneContacts)
        } else {
            XCTAssertFalse(sut.isAuthorizedToAccessPhoneContacts)
        }
    }
}
