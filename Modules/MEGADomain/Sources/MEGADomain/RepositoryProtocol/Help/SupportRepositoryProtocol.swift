import Combine

public protocol SupportRepositoryProtocol {
    func createSupportTicket(withMessage message: String) -> Future<Void, CreateSupportTicketErrorEntity>
}
