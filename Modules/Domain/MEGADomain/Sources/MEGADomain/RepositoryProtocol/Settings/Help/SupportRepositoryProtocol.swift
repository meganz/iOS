public protocol SupportRepositoryProtocol: RepositoryProtocol, Sendable {
    func createSupportTicket(withMessage message: String) async throws
}
