import MEGADomain

public struct MockContactLinkRepository: ContactLinkRepositoryProtocol {
    public static var newRepo: MockContactLinkRepository {
        MockContactLinkRepository()
    }
    
    public func contactLinkQuery(handle: HandleEntity) async throws -> ContactLinkEntity? {
        ContactLinkEntity(email: "email", name: "name")
    }
}
