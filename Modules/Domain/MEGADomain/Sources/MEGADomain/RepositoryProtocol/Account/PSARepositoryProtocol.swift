public protocol PSARepositoryProtocol: RepositoryProtocol, Sendable {
    func getPSA() async throws -> PSAEntity
    func markAsSeenForPSA(withIdentifier identifier: PSAIdentifier)
}
