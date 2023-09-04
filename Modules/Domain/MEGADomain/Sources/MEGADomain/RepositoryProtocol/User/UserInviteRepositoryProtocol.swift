public protocol UserInviteRepositoryProtocol: RepositoryProtocol {
    func sendInvite(forEmail email: String) async throws
}
