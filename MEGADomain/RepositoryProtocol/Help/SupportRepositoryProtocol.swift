import Combine

protocol SupportRepositoryProtocol {
    func createSupportTicket(withMessage message: String) -> Future<Void, CreateSupportTicketErrorEntity>
}
