import Contacts

public protocol DeviceContactsRepositoryProtocol: RepositoryProtocol {
    var isAuthorizedToAccessPhoneContacts: Bool { get }
    func fetchContacts() -> [CNContact]
}
