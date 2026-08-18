@testable import Accounts
import Foundation
import MEGAAppPresentation
import MEGAAppPresentationMock
import MEGADomain
import Testing
import UIKit

@MainActor
@Suite("PromoLandingOrUpgradeRouter")
struct PromoLandingOrUpgradeRouterTests {

    @Test("A resolved plan presents the promo landing dialog")
    func start_planResolved_presentsDialog() async {
        let harness = Harness(result: .success(.fake))

        await harness.sut.start()

        #expect(harness.presenter.presentedViewControllers.count == 1)
        #expect(harness.showUpgradeScreenCallCount == 0)
    }

    @Test("No promoted plan falls back to the upgrade screen")
    func start_noPlan_showsUpgradeScreen() async {
        let harness = Harness(result: .success(nil))

        await harness.sut.start()

        #expect(harness.showUpgradeScreenCallCount == 1)
        #expect(harness.presenter.presentedViewControllers.isEmpty)
    }

    @Test("A failed fetch falls back to the upgrade screen")
    func start_fetchThrows_showsUpgradeScreen() async {
        let harness = Harness(result: .failure(TestError.fetchFailed))

        await harness.sut.start()

        #expect(harness.showUpgradeScreenCallCount == 1)
        #expect(harness.presenter.presentedViewControllers.isEmpty)
    }

    @Test("Expired offers are excluded when resolving the plan")
    func start_resolvesPlanCheckingForExpiry() async {
        let harness = Harness(result: .success(.fake))

        await harness.sut.start()

        #expect(harness.useCase.checksForExpiryValues == [true])
    }

    // MARK: - Busy user
    //
    // A busy user is left alone entirely: the upgrade screen fallback would interrupt them just as much as the
    // dialog, so it is not offered as a consolation.

    @Test("A user who is busy is not interrupted, and is not sent to the upgrade screen either")
    func start_userBusyBeforeLookup_presentsNothing() async {
        let harness = Harness(result: .success(.fake), canInterruptUserAnswers: [false])

        await harness.sut.start()

        #expect(harness.presenter.presentedViewControllers.isEmpty)
        #expect(harness.showUpgradeScreenCallCount == 0)
        #expect(harness.useCase.checksForExpiryValues.isEmpty)
    }

    @Test("A user who becomes busy while the offer is resolving is not interrupted")
    func start_userBusyAfterLookup_presentsNothing() async {
        let harness = Harness(result: .success(.fake), canInterruptUserAnswers: [true, false])

        await harness.sut.start()

        #expect(harness.presenter.presentedViewControllers.isEmpty)
        #expect(harness.showUpgradeScreenCallCount == 0)
        #expect(harness.useCase.checksForExpiryValues == [true])
    }
}

// MARK: - Harness

@MainActor
private final class Harness {
    let presenter = SpyPresenter()
    let useCase: MockPromotedPlanUseCase
    private(set) var showUpgradeScreenCallCount = 0
    private(set) var sut: PromoLandingOrUpgradeRouter!
    /// One answer per `canInterruptUser` check, in order. An exhausted list answers true, which is what the cases
    /// that are not about interruptibility want.
    private var canInterruptUserAnswers: [Bool]

    init(
        result: Result<PromotedPlanEntity?, any Error>,
        canInterruptUserAnswers: [Bool] = []
    ) {
        self.canInterruptUserAnswers = canInterruptUserAnswers
        useCase = MockPromotedPlanUseCase(result: result)
        sut = PromoLandingOrUpgradeRouter(
            presenter: { [presenter] in presenter },
            promotedPlanUseCase: useCase,
            planPurchaser: MockPlanPurchasing(),
            showUpgradeScreen: { [weak self] in self?.showUpgradeScreenCallCount += 1 },
            canInterruptUser: { [weak self] in self?.nextCanInterruptUser() ?? true }
        )
    }

    private func nextCanInterruptUser() -> Bool {
        guard !canInterruptUserAnswers.isEmpty else { return true }
        return canInterruptUserAnswers.removeFirst()
    }
}

// MARK: - Doubles

private final class SpyPresenter: UIViewController {
    private(set) var presentedViewControllers: [UIViewController] = []

    override func present(
        _ viewControllerToPresent: UIViewController,
        animated flag: Bool,
        completion: (() -> Void)? = nil
    ) {
        presentedViewControllers.append(viewControllerToPresent)
    }
}

private final class MockPromotedPlanUseCase: PromotedPlanUseCaseProtocol, @unchecked Sendable {
    private let result: Result<PromotedPlanEntity?, any Error>
    private(set) var checksForExpiryValues: [Bool] = []

    init(result: Result<PromotedPlanEntity?, any Error>) {
        self.result = result
    }

    func fetchPromotedPlan(checksForExpiry: Bool) async throws -> PromotedPlanEntity? {
        checksForExpiryValues.append(checksForExpiry)
        return try result.get()
    }
}

private enum TestError: Error {
    case fetchFailed
}

private extension PromotedPlanEntity {
    static var fake: PromotedPlanEntity {
        let offer = MobileOfferEntity(
            id: "promo-offer",
            useAsTitle: false,
            label: nil,
            discountPercentage: 50,
            flags: 1,
            reshowTimeout: 3600,
            expiryDate: nil,
            iosOfferId: nil,
            iosSignature: nil,
            campaignId: 1
        )

        return PromotedPlanEntity(
            plan: PlanEntity(
                productIdentifier: "pro1.oneYear",
                type: .proI,
                name: "Pro I",
                currency: "USD",
                subscriptionCycle: .yearly,
                storage: "2 TB",
                transfer: "2 TB",
                price: 99.99,
                formattedPrice: "$99.99",
                introductoryOffer: SubscriptionOfferEntity(
                    price: 49.99,
                    period: BillingPeriod(unit: .year, value: 1),
                    periodCount: 1,
                    paymentMode: .payUpFront
                ),
                mobileOffer: offer
            ),
            offer: offer
        )
    }
}
