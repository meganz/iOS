import Contacts
import XCTest

final class CNContactTests: XCTestCase {
    func testExtractPhoneNumbers_whenExtractingPhoneNumbers_shouldReturnCorrectPhoneNumbers() {
        let phoneNumberFirst = CNPhoneNumber(stringValue: "123-456-7890")
        let phoneNumberSecond = CNPhoneNumber(stringValue: "098-765-4321")

        let firstContact = CNMutableContact()
        firstContact.phoneNumbers = [CNLabeledValue(label: CNLabelWork, value: phoneNumberFirst)]

        let secondContact = CNMutableContact()
        secondContact.phoneNumbers = [CNLabeledValue(label: CNLabelHome, value: phoneNumberSecond)]

        let sut = [firstContact, secondContact]

        let result = sut.extractPhoneNumbers()

        XCTAssertEqual(result, ["123-456-7890", "098-765-4321"])
    }

    func testExtractEmails_whenExtractingEmails_shouldReturnCorrectEmails() {
        let emailFirst = CNLabeledValue(label: CNLabelHome, value: "first@example.com" as NSString)
        let emailSecond = CNLabeledValue(label: CNLabelWork, value: "second@example.com" as NSString)

        let firstContact = CNMutableContact()
        firstContact.emailAddresses = [emailFirst]

        let secondContact = CNMutableContact()
        secondContact.emailAddresses = [emailSecond]

        let sut = [firstContact, secondContact]

        let result = sut.extractEmails()

        XCTAssertEqual(result, ["first@example.com", "second@example.com"])
    }

    func testExtractPhoneNumbers_whenMultiplePhoneNumbers_shouldReturnFirstPhoneNumber() {
        let phoneNumberFirst = CNPhoneNumber(stringValue: "123-456-7890")
        let phoneNumberSecond = CNPhoneNumber(stringValue: "098-765-4321")

        let firstContact = CNMutableContact()
        firstContact.phoneNumbers = [
            CNLabeledValue(label: CNLabelWork, value: phoneNumberFirst),
            CNLabeledValue(label: CNLabelHome, value: phoneNumberSecond)
        ]

        let sut = [firstContact]

        let result = sut.extractPhoneNumbers()

        XCTAssertEqual(result, ["123-456-7890"])
    }

    func testExtractEmails_whenMultipleEmails_shouldReturnFirstEmail() {
        let emailFirst = CNLabeledValue(label: CNLabelHome, value: "first@example.com" as NSString)
        let emailSecond = CNLabeledValue(label: CNLabelWork, value: "second@example.com" as NSString)

        let firstContact = CNMutableContact()
        firstContact.emailAddresses = [emailFirst, emailSecond]

        let sut = [firstContact]

        let result = sut.extractEmails()

        XCTAssertEqual(result, ["first@example.com"])
    }
}
