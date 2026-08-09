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
        
        async let account = accountUseCase.refreshCurrentAccountDetails()
        async let plans = accountPlanProductsUseCase.availablePlans()

        let (accountDetails, catalog) = try await (account, plans)

        try Task.checkCancellation()
        
        if let recommendedPlan = recommendedUpgradePlanUseCase.recommend(for: accountDetails, from: catalog) {
            return .available(accountDetails: accountDetails, recommendedPlan: recommendedPlan)
        } else {
            return .unavailable(accountDetails: accountDetails)
        }
    }
}
