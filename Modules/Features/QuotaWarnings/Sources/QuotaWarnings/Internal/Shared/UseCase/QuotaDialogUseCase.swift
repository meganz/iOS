import MEGADomain

struct QuotaDialogUseCase: QuotaDialogUseCaseProtocol {
    private let accountUseCase: any AccountUseCaseProtocol
    private let accountPlanProductsUseCase: any AccountPlanProductsUseCaseProtocol
    private let recommendedUpgradePlanUseCase: any RecommendedUpgradePlanUseCaseProtocol
    private let pricingRequester: any PricingRequesting
    
    init(
        accountUseCase: some AccountUseCaseProtocol,
        accountPlanProductsUseCase: some AccountPlanProductsUseCaseProtocol,
        recommendedUpgradePlanUseCase: some RecommendedUpgradePlanUseCaseProtocol,
        pricingRequester: some PricingRequesting
    ) {
        self.accountUseCase = accountUseCase
        self.accountPlanProductsUseCase = accountPlanProductsUseCase
        self.recommendedUpgradePlanUseCase = recommendedUpgradePlanUseCase
        self.pricingRequester = pricingRequester
    }

    var userEmail: String? {
        accountUseCase.myEmail
    }

    func upgradeOption() async throws -> QuotaUpgradeOption {
        try await pricingRequester.requestPricing()
        
        try Task.checkCancellation()
        
        return if accountUseCase.isLoggedIn() {
            try await loggedInUpgradeOption()
        } else {
            try await loggedOutUpgradeOption()
        }
    }
    
    private func loggedInUpgradeOption() async throws -> QuotaUpgradeOption {
        async let account = accountUseCase.getCurrentAccountDetails()
        async let plans = accountPlanProductsUseCase.availablePlans()

        let (accountDetails, catalog) = try await (account, plans)

        try Task.checkCancellation()
        
        return if let recommendedPlan = recommendedUpgradePlanUseCase.recommend(for: accountDetails, from: catalog) {
            .available(accountDetails: accountDetails, recommendedPlan: recommendedPlan)
        } else {
            .unavailable(accountDetails: accountDetails)
        }
    }
    
    private func loggedOutUpgradeOption() async throws -> QuotaUpgradeOption {
        let plans = await accountPlanProductsUseCase.availablePlans()
        
        try Task.checkCancellation()
        
        let plan = try recommendedUpgradePlanUseCase.recommendForNewAccount(from: plans)
        return .signIn(recommendedPlan: plan)
    }
}
