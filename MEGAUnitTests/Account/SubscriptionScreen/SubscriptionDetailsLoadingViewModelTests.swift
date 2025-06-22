@testable import MEGA
import MEGAAppSDKRepo
import MEGAAppSDKRepoMock
import MEGADomain
import MEGADomainMock
import Testing

struct SubscriptionDetailsLoadingViewModelTests {

    @Test("verify account details when current account details are already available")
    @MainActor
    func verifyAccountDetailsWhenCurrentAccountDetailsAreAlreadyAvailable() async {
        let currentDetails = MockMEGAAccountDetails(type: .free).toAccountDetailsEntity()
        let accountUseCase = MockAccountUseCase(currentAccountDetails: currentDetails)
        await assert(accountUseCase: accountUseCase, currentDetails: currentDetails)
    }

    @Test("verify account details when current account details are fetched")
    @MainActor
    func verifyAccountDetailsWhenAccountDetailsAreFetched() async {
        let currentDetails = MockMEGAAccountDetails(type: .free).toAccountDetailsEntity()
        let accountUseCase = MockAccountUseCase(accountDetailsResult: .success(currentDetails))
        await assert(accountUseCase: accountUseCase, refreshAccountDetails_calledCount: 1, currentDetails: currentDetails)
    }
    
    @Test("non free account should route to dismiss")
    @MainActor
    func nonFreeAccount() async {
        let accountUseCase = MockAccountUseCase(
            accountDetailsResult: .success(.build(proLevel: .proI)))
        let viewModel = makeSUT(
            accountUseCase: accountUseCase
        )
        
        #expect(await viewModel.determineRoute() == .dismiss)
    }
    
    @Test("dismiss if failed to retrieve account details")
    @MainActor
    func failedToRetrieveAccount() async {
        let accountUseCase = MockAccountUseCase(
            accountDetailsResult: .failure(AccountDetailsErrorEntity.generic))
        let viewModel = makeSUT(
            accountUseCase: accountUseCase
        )
        
        #expect(await viewModel.determineRoute() == .dismiss)
    }

    @MainActor
    private func assert(
        accountUseCase: MockAccountUseCase,
        refreshAccountDetails_calledCount: Int = 0,
        currentDetails: AccountDetailsEntity
    ) async {
        let purchase = MockMEGAPurchase()

        let viewModel = makeSUT(
            accountUseCase: accountUseCase,
            purchase: purchase
        )

        let loadTask = Task {
            return await viewModel.determineRoute()
        }

        let pricingReadyTask = Task(priority: .low) {
            if let test = purchase.purchaseDelegateMutableArray?.first as? (any MEGAPurchasePricingDelegate) {
                test.pricingsReady()
            }
        }

        _ = await pricingReadyTask.value
        let details = await loadTask.value
        #expect(accountUseCase.refreshAccountDetails_calledCount == refreshAccountDetails_calledCount)
        #expect(details == .goPro(currentDetails))
    }

    @MainActor
    private func makeSUT(
        accountUseCase: some AccountUseCaseProtocol = MockAccountUseCase(),
        purchase: MEGAPurchase = MockMEGAPurchase()
    ) -> SubscriptionDetailsLoadingViewModel {
        SubscriptionDetailsLoadingViewModel(accountUseCase: accountUseCase, purchase: purchase)
    }
}
