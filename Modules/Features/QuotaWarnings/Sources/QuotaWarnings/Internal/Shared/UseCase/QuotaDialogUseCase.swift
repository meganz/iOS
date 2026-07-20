import MEGADomain

struct QuotaDialogUseCase: QuotaDialogUseCaseProtocol {
    private let accountUseCase: any AccountUseCaseProtocol
    private let accountPlanProductsUseCase: any AccountPlanProductsUseCaseProtocol
    private let recommendedUpgradePlanUseCase: any RecommendedUpgradePlanUseCaseProtocol

    init(
        accountUseCase: some AccountUseCaseProtocol,
        accountPlanProductsUseCase: some AccountPlanProductsUseCaseProtocol,
        recommendedUpgradePlanUseCase: some RecommendedUpgradePlanUseCaseProtocol
    ) {
        self.accountUseCase = accountUseCase
        self.accountPlanProductsUseCase = accountPlanProductsUseCase
        self.recommendedUpgradePlanUseCase = recommendedUpgradePlanUseCase
    }

    func upgradeOption() async throws -> QuotaUpgradeOption {
        async let account = accountUseCase.refreshCurrentAccountDetails()
        async let plans = accountPlanProductsUseCase.availablePlans()

        let (accountDetails, catalog) = try await (account, plans)

        if let recommendedPlan = recommendedUpgradePlanUseCase.recommend(for: accountDetails, from: catalog) {
            return .available(accountDetails: accountDetails, recommendedPlan: recommendedPlan)
        } else {
            return .unavailable(accountDetails: accountDetails)
        }
    }
}
