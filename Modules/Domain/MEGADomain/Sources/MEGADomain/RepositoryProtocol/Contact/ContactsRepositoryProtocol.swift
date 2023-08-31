import Contacts

public protocol ContactsRepositoryProtocol: RepositoryProtocol {
    var isAuthorizedToAccessPhoneContacts: Bool { get }
    func fetchContacts() -> [CNContact]
}
