import MEGAAppPresentation
import MEGADomain
import MEGADomainMock
import Testing

@MainActor
@Suite("PlanPurchaseEligibilityChecker")
struct PlanPurchaseEligibilityCheckerTests {

    // MARK: - eligibility

    @Test("An account with nothing in the way may purchase")
    func eligibility_withNothingInTheWay_isPurchasable() {
        #expect(makeSUT().eligibility() == .purchasable)
    }

    @Test("Unknown account details cannot block a purchase")
    func eligibility_withoutAccountDetails_isPurchasable() {
        #expect(makeSUT(currentAccountDetails: nil).eligibility() == .purchasable)
    }

    @Test("A web subscription the app can cancel is reported as cancellable")
    func eligibility_withCancellableSubscription_isCancellable() {
        let sut = makeSUT(currentAccountDetails: details(method: .stripe2))
        #expect(sut.eligibility() == .hasCancellableSubscription)
    }

    @Test("A subscription the app cannot cancel is reported as such")
    func eligibility_withNonCancellableSubscription_isNonCancellable() {
        let sut = makeSUT(currentAccountDetails: details(method: .googleWallet))
        #expect(sut.eligibility() == .hasNonCancellableSubscription)
    }

    // MARK: - cancelActiveSubscription

    @Test("A cancellation the API accepts succeeds")
    func cancelActiveSubscription_whenTheRequestSucceeds_isTrue() async {
        #expect(await makeSUT().cancelActiveSubscription())
    }

    @Test("A cancellation the API rejects fails")
    func cancelActiveSubscription_whenTheRequestFails_isFalse() async {
        let sut = makeSUT(cancelResult: .failure(.generic))
        #expect(await sut.cancelActiveSubscription() == false)
    }

    // MARK: - refreshedEligibility

    @Test("A refreshed account with the subscription gone may purchase")
    func refreshedEligibility_whenTheSubscriptionIsGone_isPurchasable() async {
        let sut = makeSUT(
            currentAccountDetails: details(method: .stripe2),
            refreshedAccountDetails: .build(proLevel: .free)
        )
        #expect(await sut.refreshedEligibility() == .purchasable)
    }

    @Test("A subscription that survives the cancellation still blocks")
    func refreshedEligibility_whenTheSubscriptionSurvives_isNotPurchasable() async {
        let sut = makeSUT(
            currentAccountDetails: details(method: .stripe2),
            refreshedAccountDetails: details(method: .stripe2)
        )
        #expect(await sut.refreshedEligibility() == .hasCancellableSubscription)
    }

    @Test("A refresh that fails cannot block the purchase")
    func refreshedEligibility_whenTheRefreshFails_isPurchasable() async {
        let sut = makeSUT(currentAccountDetails: details(method: .stripe2))
        #expect(await sut.refreshedEligibility() == .purchasable)
    }

    // MARK: - SUT

    private func makeSUT(
        currentAccountDetails: AccountDetailsEntity? = nil,
        refreshedAccountDetails: AccountDetailsEntity? = nil,
        cancelResult: Result<Void, AccountErrorEntity> = .success(())
    ) -> PlanPurchaseEligibilityChecker {
        PlanPurchaseEligibilityChecker(
            subscriptionsUseCase: MockSubscriptionsUseCase(requestResult: cancelResult),
            accountUseCase: MockAccountUseCase(
                currentAccountDetails: currentAccountDetails,
                accountDetailsResult: refreshedAccountDetails.map { .success($0) } ?? .failure(.generic)
            )
        )
    }

    private nonisolated func details(method: PaymentMethodEntity) -> AccountDetailsEntity {
        .build(proLevel: .proI, subscriptionStatus: .valid, subscriptionMethodId: method)
    }
}
