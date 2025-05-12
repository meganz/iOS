import MEGAAppSDKRepo
import MEGADomain

struct SubscriptionDetailsLoadingViewModel {
    let accountUseCase: any AccountUseCaseProtocol
    let purchase: MEGAPurchase

    init(accountUseCase: some AccountUseCaseProtocol, purchase: MEGAPurchase = .sharedInstance()) {
        self.accountUseCase = accountUseCase
        self.purchase = purchase
    }

    func load() async throws -> AccountDetailsEntity {
        let accountDetails = try await loadAccountDetails()
        await purchase.requestPricingAsync()
        return accountDetails
    }

    private func loadAccountDetails() async throws -> AccountDetailsEntity {
        if let details = accountUseCase.currentAccountDetails {
            return details
        }
        return try await accountUseCase.refreshCurrentAccountDetails()
    }
}
