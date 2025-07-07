import Contacts
import Intents

public extension Array where Element: CNContact {

    func extractEmails() -> [String] {
        self
            .compactMap { $0.emailAddresses.first?.value as String? }
    }

    func extractPhoneNumbers() -> [String] {
        self
            .compactMap { $0.phoneNumbers.first?.value.stringValue }
    }
}
