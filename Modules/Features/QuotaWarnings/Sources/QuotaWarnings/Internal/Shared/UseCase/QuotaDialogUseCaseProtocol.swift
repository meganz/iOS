import MEGADomain

protocol QuotaDialogUseCaseProtocol: Sendable {
    func accountDetails() async throws -> AccountDetailsEntity
    func recommendedPlan() async throws -> PlanEntity?
}
