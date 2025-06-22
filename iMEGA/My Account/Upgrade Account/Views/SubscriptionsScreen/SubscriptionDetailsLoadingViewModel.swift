import MEGAAppSDKRepo
import MEGADomain

@MainActor
struct SubscriptionDetailsLoadingViewModel {
    enum Route: Equatable {
        case goPro(AccountDetailsEntity)
        case dismiss
    }
    private let accountUseCase: any AccountUseCaseProtocol
    private let purchase: MEGAPurchase

    init(accountUseCase: some AccountUseCaseProtocol, purchase: MEGAPurchase = .sharedInstance()) {
        self.accountUseCase = accountUseCase
        self.purchase = purchase
    }

    func determineRoute() async -> Route {
        guard let accountDetails = await loadAccountDetails(),
              accountDetails.proLevel == .free else {
            return .dismiss
        }
        await purchase.requestPricingAsync()
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
