public protocol SupportRepositoryProtocol: RepositoryProtocol {
    func createSupportTicket(withMessage message: String) async throws 
}
