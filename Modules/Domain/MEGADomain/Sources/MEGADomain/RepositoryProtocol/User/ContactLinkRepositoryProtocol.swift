import Combine

public protocol ContactLinkRepositoryProtocol: RepositoryProtocol {
    func contactLinkQuery(handle: HandleEntity) async throws -> ContactLinkEntity?
}
