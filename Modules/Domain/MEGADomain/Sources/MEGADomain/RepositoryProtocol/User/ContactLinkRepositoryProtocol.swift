import Combine

public protocol ContactLinkRepositoryProtocol: RepositoryProtocol, Sendable {
    func contactLinkQuery(handle: HandleEntity) async throws -> ContactLinkEntity?
}
