import MEGADomain

struct ContactsRepository: ContactsRepositoryProtocol {    
    var isAuthorizedToAccessPhoneContacts: Bool {
        CNContactStore.authorizationStatus(for: .contacts) == .authorized
    }
}

