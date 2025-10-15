public protocol UserInviteRepositoryProtocol: RepositoryProtocol, Sendable {
    func sendInvite(forEmail email: String) async throws
}
