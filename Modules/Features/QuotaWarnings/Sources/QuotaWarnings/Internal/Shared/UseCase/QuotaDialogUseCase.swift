import MEGADomain

struct QuotaDialogUseCase: QuotaDialogUseCaseProtocol {
    private let accountUseCase: any AccountUseCaseProtocol

    init(accountUseCase: some AccountUseCaseProtocol) {
        self.accountUseCase = accountUseCase
    }

    func upgradeOption() async throws -> QuotaUpgradeOption {
        async let account = accountUseCase.refreshCurrentAccountDetails()
        async let plan = recommendedPlan()

        let (accountDetails, planEntity) = try await (account, plan)

        if let planEntity {
            return .available(accountDetails: accountDetails, plan: planEntity)
        } else {
            return .unavailable(accountDetails: accountDetails)
        }
    }

    // real recommended-plan selection is wired in a later step.
    private func recommendedPlan() async throws -> PlanEntity? {
        .mockEssentialYearly
    }
}
