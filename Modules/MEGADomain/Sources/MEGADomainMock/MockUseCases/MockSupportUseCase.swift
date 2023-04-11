import MEGADomain

public struct MockSupportUseCase: SupportUseCaseProtocol {
    let createSupportTicketResult: Result<Void, GenericErrorEntity>

    public init(createSupportTicketResult: Result<Void, GenericErrorEntity> = .failure(GenericErrorEntity())) {
        self.createSupportTicketResult = createSupportTicketResult
    }

    public func createSupportTicket(withMessage message: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            continuation.resume(with: createSupportTicketResult)
        }
    }
}
