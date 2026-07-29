@testable import Accounts
import Foundation
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import MEGAStoreKitMocks
import Testing

@MainActor
@Suite("UpgradePlansContainerViewModel")
struct UpgradePlansContainerViewModelTests {

    // MARK: - loadData

    @Test("No promotional offer loads the standard page")
    func loadData_noPromo_showsStandard() async {
        let sut = makeSUT(plans: [standardPlan()])
        await sut.loadData()
        #expect(sut.viewState.isStandard)
    }

    @Test("A live promotional offer loads the promo page")
    func loadData_promoWithFutureDeadline_showsPromo() async {
        let sut = makeSUT(plans: [promoPlan()], hasAlreadyExpired: false)
        await sut.loadData()
        #expect(sut.viewState.isPromo)
    }

    @Test("An already-expired promotional offer loads the standard page")
    func loadData_promoAlreadyExpired_showsStandard() async {
        let sut = makeSUT(plans: [promoPlan()], hasAlreadyExpired: true)
        await sut.loadData()
        #expect(sut.viewState.isStandard)
    }

    // MARK: - monitorPromoExpiry

    @Test("When the monitored offer lapses, the offer-ended alert is presented")
    func monitorPromoExpiry_whenOfferLapses_presentsPromoEndedAlert() async {
        let sut = makeSUT(plans: [promoPlan()], monitorExpires: true)
        await sut.loadData()
        await sut.monitorPromoExpiry()
        #expect(sut.isAlertPresented)
        #expect(sut.alertType?.isPromoEnded == true)
        #expect(sut.viewState.isPromo) // still promo until the user taps through
    }

    @Test("A cancelled wait presents no alert and stays on the promo page")
    func monitorPromoExpiry_whenCancelled_doesNothing() async {
        let sut = makeSUT(plans: [promoPlan()], monitorExpires: false)
        await sut.loadData()
        await sut.monitorPromoExpiry()
        #expect(sut.isAlertPresented == false)
        #expect(sut.viewState.isPromo)
    }

    @Test("Tapping View plans flips to the standard page carrying the selected cycle")
    func promoEndedAlertAction_flipsToStandardCarryingCycle() async {
        let sut = makeSUT(plans: [promoPlan()], monitorExpires: true)
        await sut.loadData()

        guard case .promo(let promoViewModel) = sut.viewState else {
            Issue.record("Expected the promo page after loading a live promotional offer")
            return
        }
        promoViewModel.selectedCycle = .monthly

        await sut.monitorPromoExpiry()
        sut.alertType?.primaryButtonAction?()

        guard case .standard(let standardViewModel) = sut.viewState else {
            Issue.record("Expected the standard page after tapping View plans")
            return
        }
        #expect(standardViewModel.selectedCycle == .monthly)
    }

    // MARK: - SUT

    private func makeSUT(
        plans: [PlanEntity],
        accountDetails: AccountDetailsEntity = .build(),
        hasAlreadyExpired: Bool = false,
        monitorExpires: Bool = true
    ) -> UpgradePlansContainerViewModel {
        let fetchUseCase = MockRevampUpgradePlansUseCase(plansResult: plans, accountDetails: accountDetails)
        let dependency = makeDependency(
            fetchUseCase: fetchUseCase,
            accountDetails: accountDetails,
            promoExpiryMonitorFactory: MockPromoExpiryMonitorFactory(
                hasAlreadyExpired: hasAlreadyExpired,
                expires: monitorExpires
            )
        )
        return UpgradePlansContainerViewModel(dependency: dependency)
    }

    private func makeDependency(
        fetchUseCase: some RevampUpgradePlansUseCaseProtocol,
        accountDetails: AccountDetailsEntity,
        promoExpiryMonitorFactory: some PromoExpiryMonitorFactory
    ) -> RevampUpgradePlansDependency {
        RevampUpgradePlansDependency(
            fetchUseCase: fetchUseCase,
            purchaseUseCase: MockAccountPlanPurchaseUseCase(),
            subscriptionsUseCase: MockSubscriptionsUseCase(),
            accountUseCase: MockAccountUseCase(currentAccountDetails: accountDetails),
            externalPurchaseUseCase: MockExternalPurchaseUseCase(),
            remoteFeatureFlagUseCase: MockRemoteFeatureFlagUseCase(),
            termsAndPoliciesPresenter: MockTermsAndPoliciesPresenter(),
            tracker: MockTracker(),
            viewType: .upgrade,
            accountDisplayName: { _ in "" },
            domainName: "mega.nz",
            appVersion: "1.0",
            isFromAds: false,
            promoExpiryMonitorFactory: promoExpiryMonitorFactory
        )
    }

    // MARK: - Plan fixtures

    private func standardPlan() -> PlanEntity {
        PlanEntity(
            type: .proI,
            currency: "EUR",
            subscriptionCycle: .yearly,
            price: 10,
            formattedPrice: "€10"
        )
    }

    private func promoPlan(expiry: Date = Date().addingTimeInterval(3600)) -> PlanEntity {
        PlanEntity(
            type: .proI,
            currency: "EUR",
            subscriptionCycle: .yearly,
            price: 10,
            formattedPrice: "€10",
            mobileOffer: MobileOfferEntity(
                id: "promo",
                useAsTitle: false,
                label: nil,
                discountPercentage: 50,
                flags: 0,
                reshowTimeout: nil,
                expiryDate: expiry,
                iosOfferId: "promo",
                iosSignature: MobileOfferIosSignatureEntity(offerId: "promo", keyId: "key", nonce: "nonce", timestamp: 0, signature: "sig")
            ),
            promotionalOffer: SubscriptionOfferEntity(price: 5)
        )
    }
}

// MARK: - Test doubles

private struct MockRevampUpgradePlansUseCase: RevampUpgradePlansUseCaseProtocol {
    var plansResult: [PlanEntity] = []
    var accountDetails: AccountDetailsEntity = .build()

    func plans() async -> [PlanEntity] { plansResult }
    func currentAccountDetails() async throws -> AccountDetailsEntity { accountDetails }
}

private struct MockPromoExpiryMonitorFactory: PromoExpiryMonitorFactory {
    var hasAlreadyExpired = false
    var expires = true

    func makeMonitor(deadline: Date, accountDetails: AccountDetailsEntity, plans: [PlanEntity]) -> any PromoExpiryMonitoring {
        MockPromoExpiryMonitor(
            hasAlreadyExpired: hasAlreadyExpired,
            expires: expires,
            accountDetails: accountDetails,
            plansAfterExpiry: plans
        )
    }
}

@MainActor
private final class MockPromoExpiryMonitor: PromoExpiryMonitoring {
    let hasAlreadyExpired: Bool
    let accountDetails: AccountDetailsEntity
    let plansAfterExpiry: [PlanEntity]
    private let expires: Bool
    private(set) var waitUntilExpiredCallCount = 0

    init(
        hasAlreadyExpired: Bool = false,
        expires: Bool = true,
        accountDetails: AccountDetailsEntity = .build(),
        plansAfterExpiry: [PlanEntity] = []
    ) {
        self.hasAlreadyExpired = hasAlreadyExpired
        self.expires = expires
        self.accountDetails = accountDetails
        self.plansAfterExpiry = plansAfterExpiry
    }

    func waitUntilExpired() async -> Bool {
        waitUntilExpiredCallCount += 1
        return expires
    }
}

@MainActor
private final class MockTermsAndPoliciesPresenter: TermsAndPoliciesPresenting {
    private(set) var showTermsAndPoliciesCallCount = 0
    func showTermsAndPolicies() { showTermsAndPoliciesCallCount += 1 }
}

// MARK: - View state / alert matchers

private extension UpgradePlansContainerViewModel.ViewState {
    var isStandard: Bool { if case .standard = self { true } else { false } }
    var isPromo: Bool { if case .promo = self { true } else { false } }
}

private extension UpgradeAccountPlanAlertType {
    var isPromoEnded: Bool { if case .promoEnded = self { true } else { false } }
}
