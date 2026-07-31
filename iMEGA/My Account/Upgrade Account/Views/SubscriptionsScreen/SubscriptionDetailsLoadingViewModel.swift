import MEGAAppSDKRepo
import MEGADomain

@MainActor
struct SubscriptionDetailsLoadingViewModel {
    enum Route: Equatable {
        case goPro(AccountDetailsEntity)
        case dismiss
    }
    private let accountUseCase: any AccountUseCaseProtocol
    private let pricingRequester: any PricingRequesting

    init(
        accountUseCase: some AccountUseCaseProtocol,
        pricingRequester: some PricingRequesting = PricingRequester.shared
    ) {
        self.accountUseCase = accountUseCase
        self.pricingRequester = pricingRequester
    }

    func determineRoute() async -> Route {
        guard let accountDetails = await loadAccountDetails(),
              accountDetails.proLevel == .free else {
            return .dismiss
        }
        try? await pricingRequester.requestPricing()
        return .goPro(accountDetails)
    }

    private func loadAccountDetails() async -> AccountDetailsEntity? {
        if let details = accountUseCase.currentAccountDetails {
            return details
        }
        do {
            return try await accountUseCase.refreshCurrentAccountDetails()
        } catch {
            MEGALogError("[\(type(of: self))]: failed to load account details error: \(error.localizedDescription)")
        }
        return nil
    }
}
