import MEGADomain
import MEGADomainMock
import Testing

@Suite("AccountSubscriptionValidationUseCase")
struct AccountSubscriptionValidationUseCaseTests {
    private func sut() -> AccountSubscriptionValidationUseCase {
        AccountSubscriptionValidationUseCase()
    }

    @Test("Free account is always purchasable")
    func freeAccount() {
        let details = AccountDetailsEntity.build(
            proLevel: .free, subscriptionStatus: .valid, subscriptionMethodId: .stripe2
        )
        #expect(sut().eligibility(for: details) == .purchasable)
    }

    @Test("Non-valid subscription is purchasable regardless of method")
    func invalidSubscription() {
        let details = AccountDetailsEntity.build(
            proLevel: .proI, subscriptionStatus: .invalid, subscriptionMethodId: .ECP
        )
        #expect(sut().eligibility(for: details) == .purchasable)
    }

    @Test("Active iTunes subscription is purchasable (Apple manages it)")
    func iTunesSubscription() {
        let details = AccountDetailsEntity.build(
            proLevel: .proI, subscriptionStatus: .valid, subscriptionMethodId: .itunes
        )
        #expect(sut().eligibility(for: details) == .purchasable)
    }

    @Test("Active web credit-card subscriptions are cancellable", arguments: [
        PaymentMethodEntity.ECP, .sabadell, .stripe2
    ])
    func cancellableSubscriptions(method: PaymentMethodEntity) {
        let details = AccountDetailsEntity.build(
            proLevel: .proI, subscriptionStatus: .valid, subscriptionMethodId: method
        )
        #expect(sut().eligibility(for: details) == .hasCancellableSubscription)
    }

    @Test("Other active non-iTunes subscriptions are non-cancellable", arguments: [
        PaymentMethodEntity.googleWallet, .stripe, .paypal, .creditCard
    ])
    func nonCancellableSubscriptions(method: PaymentMethodEntity) {
        let details = AccountDetailsEntity.build(
            proLevel: .proI, subscriptionStatus: .valid, subscriptionMethodId: method
        )
        #expect(sut().eligibility(for: details) == .hasNonCancellableSubscription)
    }
}
