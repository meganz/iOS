@testable import Accounts
import Foundation
import MEGAAppPresentation
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

    @Test("When the monitored offer lapses, it flips to standard and presents the offer-ended alert")
    func monitorPromoExpiry_whenOfferLapses_presentsPromoEndedAlert() async {
        let sut = makeSUT(plans: [promoPlan()], monitorExpires: true)
        await sut.loadData()
        await sut.monitorPromoExpiry()
        #expect(sut.isAlertPresented)
        #expect(sut.alertType?.isPromoEnded == true)
        #expect(sut.viewState.isStandard) // flips immediately; the alert is only informational
    }

    @Test("A cancelled wait presents no alert and stays on the promo page")
    func monitorPromoExpiry_whenCancelled_doesNothing() async {
        let sut = makeSUT(plans: [promoPlan()], monitorExpires: false)
        await sut.loadData()
        await sut.monitorPromoExpiry()
        #expect(sut.isAlertPresented == false)
        #expect(sut.viewState.isPromo)
    }

    @Test("When the offer lapses, the flip to standard carries the selected cycle")
    func monitorPromoExpiry_flipsToStandardCarryingCycle() async {
        let sut = makeSUT(plans: [promoPlan()], monitorExpires: true)
        await sut.loadData()

        guard case .promo(let promoViewModel) = sut.viewState else {
            Issue.record("Expected the promo page after loading a live promotional offer")
            return
        }
        promoViewModel.selectedCycle = .monthly

        await sut.monitorPromoExpiry()

        guard case .standard(let standardViewModel) = sut.viewState else {
            Issue.record("Expected the standard page after the offer lapsed")
            return
        }
        #expect(standardViewModel.selectedCycle == .monthly)
    }

    // MARK: - Purchase outcomes

    @Test("A successful purchase notifies the host exactly once")
    func purchaseSucceeded_notifiesTheHostExactlyOnce() async {
        let purchaser = MockPlanPurchasing()
        await confirmation("The host is notified of the purchase") { notified in
            let sut = makeSUT(
                plans: [standardPlan()],
                purchaser: purchaser,
                notifyPurchaseSucceeded: { notified() }
            )
            send(.succeeded, from: purchaser, to: sut)
        }
    }

    @Test("A successful purchase dismisses the page by default")
    func purchaseSucceeded_withDismissBehavior_dismissesThePage() {
        let purchaser = MockPlanPurchasing()
        let sut = makeSUT(plans: [standardPlan()], purchaser: purchaser)

        send(.succeeded, from: purchaser, to: sut)

        #expect(sut.isDismiss)
    }

    @Test("A successful purchase runs the host action instead of dismissing the page")
    func purchaseSucceeded_withPerformBehavior_runsTheActionAndKeepsThePage() async {
        let purchaser = MockPlanPurchasing()
        await confirmation("The host action runs") { performed in
            let sut = makeSUT(
                plans: [standardPlan()],
                purchaser: purchaser,
                purchaseCompleteBehavior: .perform { performed() }
            )

            send(.succeeded, from: purchaser, to: sut)

            #expect(sut.isDismiss == false)
        }
    }

    @Test("A failed purchase surfaces the failure alert and keeps the page")
    func purchaseFailed_presentsTheFailureAlertAndKeepsThePage() {
        let purchaser = MockPlanPurchasing()
        let sut = makeSUT(plans: [standardPlan()], purchaser: purchaser)

        send(.failed, from: purchaser, to: sut)

        #expect(sut.purchaseViewModel.presentedAlert?.isFailed == true)
        #expect(sut.isDismiss == false)
    }

    // MARK: - External purchase wiring

    @Test("The website buttons have no view model until the plans are loaded")
    func externalPurchaseViewModel_beforeLoading_isNil() {
        let sut = makeSUT(plans: [standardPlan()], isExternalPurchaseAvailable: true)
        #expect(sut.externalPurchaseViewModel == nil)
    }

    @Test("An account that is not offered the website route gets no view model")
    func externalPurchaseViewModel_whenTheRouteIsUnavailable_staysNil() async {
        let sut = makeSUT(plans: [standardPlan()], isExternalPurchaseAvailable: false)

        await sut.loadData()

        #expect(sut.externalPurchaseViewModel == nil)
    }

    @Test("An account offered the website route gets a view model once the plans load")
    func externalPurchaseViewModel_whenTheRouteIsAvailable_isBuiltOnLoad() async {
        let sut = makeSUT(plans: [standardPlan()], isExternalPurchaseAvailable: true)

        await sut.loadData()

        #expect(sut.externalPurchaseViewModel != nil)
    }

    @Test("The website buttons are wired to the plans that were loaded")
    func externalPurchaseViewModel_buysAPlanFromTheLoadedPlans() async throws {
        let externalPurchaser = MockExternalPlanPurchasing()
        let sut = makeSUT(
            plans: [standardPlan(productIdentifier: "pro1.oneYear")],
            isExternalPurchaseAvailable: true,
            externalPurchaser: externalPurchaser
        )
        await sut.loadData()

        let externalPurchaseViewModel = try #require(sut.externalPurchaseViewModel)
        await externalPurchaseViewModel.buy(productIdentifier: "pro1.oneYear")

        #expect(externalPurchaser.purchasedPlans.map(\.productIdentifier) == ["pro1.oneYear"])
    }

    @Test("A completed website purchase settles the page the way an in-app one does")
    func externalPurchaseSucceeded_dismissesThePage() async {
        let externalPurchaser = MockExternalPlanPurchasing()
        let sut = makeSUT(
            plans: [standardPlan()],
            isExternalPurchaseAvailable: true,
            externalPurchaser: externalPurchaser
        )
        await sut.loadData()

        externalPurchaser.send(.succeeded)

        #expect(sut.isDismiss)
    }

    // MARK: - Analytics

    @Test("Appearing reports the screen view")
    func onAppear_reportsScreenView() {
        let analyticsUseCase = MockUpgradePlansAnalyticsUseCase()
        let sut = makeSUT(plans: [standardPlan()], analyticsUseCase: analyticsUseCase)

        sut.onAppear()

        #expect(analyticsUseCase.invocations == [.screenView])
    }

    @Test("A successful load hands the plans to the analytics use case")
    func loadData_handsPlansToAnalytics() async {
        let analyticsUseCase = MockUpgradePlansAnalyticsUseCase()
        let sut = makeSUT(plans: [standardPlan()], analyticsUseCase: analyticsUseCase)

        await sut.loadData()

        #expect(analyticsUseCase.invocations == [.plansDidLoad])
    }

    // MARK: - Dismissal

    @Test("Dismissing from the header reports it and dismisses the page")
    func dismiss_maybeLater_reportsAndDismisses() {
        let analyticsUseCase = MockUpgradePlansAnalyticsUseCase()
        let sut = makeSUT(plans: [standardPlan()], analyticsUseCase: analyticsUseCase)

        sut.dismiss(reason: .maybeLater)

        #expect(sut.isDismiss)
        #expect(analyticsUseCase.invocations == [.dismiss])
    }

    @Test("Carrying on with the free plan reports its own event")
    func dismiss_freePlan_reportsGetStartedForFree() {
        let analyticsUseCase = MockUpgradePlansAnalyticsUseCase()
        let sut = makeSUT(plans: [standardPlan()], analyticsUseCase: analyticsUseCase)

        sut.dismiss(reason: .freePlan)

        #expect(sut.isDismiss)
        #expect(analyticsUseCase.invocations == [.getStartedForFree])
    }

    @Test("A dismissal the screen triggers itself reports nothing", arguments: [
        UpgradePlansDismissReason.purchaseSucceeded,
        .loadFailed
    ])
    func dismiss_screenDrivenReasons_dismissWithoutReporting(reason: UpgradePlansDismissReason) {
        let analyticsUseCase = MockUpgradePlansAnalyticsUseCase()
        let sut = makeSUT(plans: [standardPlan()], analyticsUseCase: analyticsUseCase)

        sut.dismiss(reason: reason)

        #expect(sut.isDismiss)
        #expect(analyticsUseCase.invocations.isEmpty)
    }

    /// The scenario from the MR review: tapping "Maybe later" while a purchase is in flight must not let
    /// the purchase completing dismiss - or report - a second time.
    @Test("A purchase completing after the user already dismissed neither dismisses nor reports again")
    func dismiss_thenPurchaseSucceeds_doesNotDismissOrReportTwice() {
        let purchaser = MockPlanPurchasing()
        let analyticsUseCase = MockUpgradePlansAnalyticsUseCase()
        let sut = makeSUT(
            plans: [standardPlan()],
            purchaser: purchaser,
            analyticsUseCase: analyticsUseCase
        )

        sut.dismiss(reason: .maybeLater)
        send(.succeeded, from: purchaser, to: sut)

        #expect(sut.isDismiss)
        #expect(analyticsUseCase.invocations == [.dismiss])
    }

    @Test("A repeat dismissal reports only once")
    func dismiss_calledTwice_reportsOnce() {
        let analyticsUseCase = MockUpgradePlansAnalyticsUseCase()
        let sut = makeSUT(plans: [standardPlan()], analyticsUseCase: analyticsUseCase)

        sut.dismiss(reason: .maybeLater)
        sut.dismiss(reason: .maybeLater)

        #expect(analyticsUseCase.invocations == [.dismiss])
    }

    // MARK: - SUT

    private func makeSUT(
        plans: [PlanEntity],
        accountDetails: AccountDetailsEntity = .build(),
        hasAlreadyExpired: Bool = false,
        monitorExpires: Bool = true,
        purchaser: MockPlanPurchasing = MockPlanPurchasing(),
        isExternalPurchaseAvailable: Bool = false,
        externalPurchaser: MockExternalPlanPurchasing = MockExternalPlanPurchasing(),
        notifyPurchaseSucceeded: @Sendable @escaping () -> Void = {},
        purchaseCompleteBehavior: PurchaseCompleteBehavior = .dismiss,
        analyticsUseCase: MockUpgradePlansAnalyticsUseCase = MockUpgradePlansAnalyticsUseCase()
    ) -> UpgradePlansContainerViewModel {
        let fetchUseCase = MockRevampUpgradePlansUseCase(plansResult: plans, accountDetails: accountDetails)
        let dependency = makeDependency(
            fetchUseCase: fetchUseCase,
            accountDetails: accountDetails,
            promoExpiryMonitorFactory: MockPromoExpiryMonitorFactory(
                hasAlreadyExpired: hasAlreadyExpired,
                expires: monitorExpires
            ),
            planPurchaserFactory: MockPlanPurchaserFactory(
                purchaser: purchaser,
                externalPurchaser: externalPurchaser
            ),
            isExternalPurchaseAvailable: isExternalPurchaseAvailable,
            notifyPurchaseSucceeded: notifyPurchaseSucceeded,
            purchaseCompleteBehavior: purchaseCompleteBehavior,
            analyticsUseCase: analyticsUseCase
        )
        return UpgradePlansContainerViewModel(dependency: dependency)
    }

    private func send(
        _ outcome: PlanPurchaseOutcome,
        from purchaser: MockPlanPurchasing,
        to sut: UpgradePlansContainerViewModel
    ) {
        _ = sut.purchaseViewModel
        purchaser.send(outcome)
    }

    private func makeDependency(
        fetchUseCase: some RevampUpgradePlansUseCaseProtocol,
        accountDetails: AccountDetailsEntity,
        promoExpiryMonitorFactory: some PromoExpiryMonitorFactory,
        planPurchaserFactory: some PlanPurchaserFactory,
        isExternalPurchaseAvailable: Bool,
        notifyPurchaseSucceeded: @Sendable @escaping () -> Void,
        purchaseCompleteBehavior: PurchaseCompleteBehavior,
        analyticsUseCase: MockUpgradePlansAnalyticsUseCase
    ) -> RevampUpgradePlansDependency {
        RevampUpgradePlansDependency(
            fetchUseCase: fetchUseCase,
            purchaseUseCase: MockAccountPlanPurchaseUseCase(),
            subscriptionsUseCase: MockSubscriptionsUseCase(),
            accountUseCase: MockAccountUseCase(currentAccountDetails: accountDetails),
            externalPurchaseUseCase: MockExternalPurchaseUseCase(
                shouldProvideExternalPurchase: isExternalPurchaseAvailable
            ),
            termsAndPoliciesPresenter: MockTermsAndPoliciesPresenter(),
            analyticsUseCase: analyticsUseCase,
            viewType: .upgrade,
            accountDisplayName: { _ in "" },
            domainName: "mega.nz",
            appVersion: "1.0",
            notifyPurchaseSucceeded: notifyPurchaseSucceeded,
            purchaseCompleteBehavior: purchaseCompleteBehavior,
            promoExpiryMonitorFactory: promoExpiryMonitorFactory,
            planPurchaserFactory: planPurchaserFactory
        )
    }

    // MARK: - Plan fixtures

    private func standardPlan(productIdentifier: String = "pro1.oneYear") -> PlanEntity {
        PlanEntity(
            productIdentifier: productIdentifier,
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

private extension PlanPurchaseAlert {
    var isFailed: Bool { if case .failed = self { true } else { false } }
}
