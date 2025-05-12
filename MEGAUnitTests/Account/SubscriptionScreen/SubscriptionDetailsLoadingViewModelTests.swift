@testable import MEGA
import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import Testing

struct SubscriptionDetailsLoadingViewModelTests {

    @Test("verify account details when current account details are already available")
    @MainActor
    func verifyAccountDetailsWhenCurrentAccountDetailsAreAlreadyAvailable() async throws {
        let currentDetails = MockMEGAAccountDetails(type: .free).toAccountDetailsEntity()
        let accountUseCase = MockAccountUseCase(currentAccountDetails: currentDetails)
        try await assert(accountUseCase: accountUseCase, currentDetails: currentDetails)
    }

    @Test("verify account details when current account details are fetched")
    @MainActor
    func verifyAccountDetailsWhenAccountDetailsAreFetched() async throws {
        let currentDetails = MockMEGAAccountDetails(type: .free).toAccountDetailsEntity()
        let accountUseCase = MockAccountUseCase(accountDetailsResult: .success(currentDetails))
        try await assert(accountUseCase: accountUseCase, refreshAccountDetails_calledCount: 1, currentDetails: currentDetails)
    }

    private func assert(
        accountUseCase: MockAccountUseCase,
        refreshAccountDetails_calledCount: Int = 0,
        currentDetails: AccountDetailsEntity
    ) async throws {
        let purchase = MockMEGAPurchase()

        let viewModel = makeSUT(
            accountUseCase: accountUseCase,
            purchase: purchase
        )

        let loadTask = Task {
            return try await viewModel.load()
        }

        let pricingReadyTask = Task(priority: .low) {
            if let test = purchase.purchaseDelegateMutableArray?.first as? (any MEGAPurchasePricingDelegate) {
                test.pricingsReady()
            }
        }

        _ = await pricingReadyTask.value
        let details = try await loadTask.value
        #expect(accountUseCase.refreshAccountDetails_calledCount == refreshAccountDetails_calledCount)
        #expect(details == currentDetails)
    }

    private func makeSUT(
        accountUseCase: some AccountUseCaseProtocol = MockAccountUseCase(),
        purchase: MEGAPurchase = MockMEGAPurchase()
    ) -> SubscriptionDetailsLoadingViewModel {
        SubscriptionDetailsLoadingViewModel(accountUseCase: accountUseCase, purchase: purchase)
    }
}
