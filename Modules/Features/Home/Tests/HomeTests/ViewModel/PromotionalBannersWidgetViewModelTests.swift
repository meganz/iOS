@testable import Home
import Foundation
import MEGAAnalyticsiOS
import MEGAAppPresentationMock
import MEGADomain
import MEGADomainMock
import Testing

@MainActor
@Suite("PromotionalBannersWidgetViewModel discount banner analytics")
struct PromotionalBannersWidgetViewModelTests {

    @Test("A discount banner on screen is reported as an impression")
    func trackDiscountBannerDisplayed_reportsTheImpression() {
        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker)

        sut.trackDiscountBannerDisplayed()

        #expect(tracker.trackedEventIdentifiers.count == 1)
        #expect(tracker.trackedEventIdentifiers.first is HomeSubscriptionOfferBannerDisplayedEvent)
    }

    @Test("Tapping the discount banner reports the press")
    func trackDiscountBannerTapped_reportsThePress() {
        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker)

        sut.trackDiscountBannerTapped()

        #expect(tracker.trackedEventIdentifiers.count == 1)
        #expect(tracker.trackedEventIdentifiers.first is HomeSubscriptionOfferBannerPressedEvent)
    }

    /// The press is reported even with no cached plan to persist the dismissal against, because the
    /// user pressed the button either way.
    @Test("Closing the discount banner reports the dismiss press and hides the banner")
    func closeDiscountBanner_reportsTheDismissPress() {
        let tracker = MockTracker()
        let sut = makeSUT(tracker: tracker)

        sut.closeDiscountBanner()

        #expect(sut.discountBanner == nil)
        #expect(tracker.trackedEventIdentifiers.count == 1)
        #expect(tracker.trackedEventIdentifiers.first is HomeSubscriptionOfferBannerDismissButtonPressedEvent)
    }

    // MARK: - Dismissal after a purchase

    /// The offer is withdrawn once the user converts, so the banner has to go without waiting for the
    /// widget to be loaded again. The cached plan goes too, otherwise returning to Home would show it.
    @Test("A successful purchase hides the discount banner and forgets the cached plan")
    func planPurchase_hidesTheBannerAndClearsTheCache() async throws {
        let (purchases, purchase) = AsyncStream<Void>.makeStream()
        let cache = PromotionalBannerCache(accountUseCase: MockAccountUseCase())
        let sut = PromotionalBannersWidgetViewModel(
            bannerUseCase: MockUserBannerUseCase(),
            discountBannerUseCase: MockDiscountBannerUseCase(promotedPlan: .homeBannerPlan()),
            discountBannerMapper: .stub(planPrice: .discounted(percentage: 50)),
            cache: cache,
            tracker: MockTracker(),
            planPurchases: purchases.eraseToAnyAsyncSequence()
        )

        await sut.onTask()
        #expect(sut.discountBanner != nil)
        #expect(cache.cachedPromotedPlan != nil)

        purchase.yield()

        await waitUntilDiscountBannerCleared(sut)
        #expect(sut.discountBanner == nil)
        #expect(cache.cachedPromotedPlan == nil)
    }

    /// Recorded the same way a manual close is, so a campaign the user has converted on stays away even
    /// if the offer is briefly still on the account.
    @Test("A successful purchase records the dismissal")
    func planPurchase_recordsTheDismissal() async throws {
        let (purchases, purchase) = AsyncStream<Void>.makeStream()
        let discountBannerUseCase = MockDiscountBannerUseCase(promotedPlan: .homeBannerPlan())
        let sut = PromotionalBannersWidgetViewModel(
            bannerUseCase: MockUserBannerUseCase(),
            discountBannerUseCase: discountBannerUseCase,
            discountBannerMapper: .stub(planPrice: .discounted(percentage: 50)),
            cache: PromotionalBannerCache(accountUseCase: MockAccountUseCase()),
            tracker: MockTracker(),
            planPurchases: purchases.eraseToAnyAsyncSequence()
        )

        await sut.onTask()
        purchase.yield()
        await waitUntilDiscountBannerCleared(sut)

        #expect(sut.discountBanner == nil)
        #expect(discountBannerUseCase.dismissedPlans.count == 1)
        #expect(discountBannerUseCase.dismissedPlans.first?.mobileOffer?.campaignId == 7)
    }

    // MARK: - Helpers

    /// The purchase sequence is finished straight away, so these view models never subscribe to the real
    /// notification centre and cannot be disturbed by a purchase announced elsewhere in the test run.
    private func makeSUT(tracker: MockTracker) -> PromotionalBannersWidgetViewModel {
        PromotionalBannersWidgetViewModel(
            bannerUseCase: MockUserBannerUseCase(),
            discountBannerUseCase: MockDiscountBannerUseCase(),
            cache: PromotionalBannerCache(accountUseCase: MockAccountUseCase()),
            tracker: tracker,
            planPurchases: AsyncStream<Void> { $0.finish() }.eraseToAnyAsyncSequence()
        )
    }

    /// Polls the view model instead of racing its publisher against a sleep in a task group. Handing the
    /// non-`Sendable` view model to a task group child defeats the region based isolation checker, and
    /// polling keeps the whole wait on the main actor where the view model already lives.
    private func waitUntilDiscountBannerCleared(
        _ sut: PromotionalBannersWidgetViewModel,
        timeout: TimeInterval = 10
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        while sut.discountBanner != nil, Date() < deadline {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
    }
}

// MARK: - Fixtures

private extension PlanEntity {
    static func homeBannerPlan() -> PlanEntity {
        PlanEntity(
            productIdentifier: "pro.i.monthly",
            type: .proI,
            subscriptionCycle: .monthly,
            mobileOffer: MobileOfferEntity(
                id: "black-friday-2025",
                useAsTitle: false,
                label: "Black Friday",
                discountPercentage: 50,
                flags: 1,
                reshowTimeout: nil,
                expiryDate: nil,
                iosOfferId: nil,
                iosSignature: nil,
                campaignId: 7
            )
        )
    }
}

private extension SubscriptionPlanPrice {
    static func discounted(percentage: Int, pricePerMonth: Decimal = 4.99) -> SubscriptionPlanPrice {
        .discountMonthly(
            .init(
                monthly: .init(price: 9.99, currency: "EUR"),
                offer: .init(
                    originalPrice: 9.99,
                    discountPercentage: percentage,
                    schedule: .recurring(
                        price: pricePerMonth,
                        period: BillingPeriod(unit: .month, value: 1),
                        periodCount: 1
                    )
                )
            )
        )
    }
}

private extension DiscountBannerContentMapper {
    static func stub(planPrice: SubscriptionPlanPrice) -> DiscountBannerContentMapper {
        DiscountBannerContentMapper(
            planPriceUseCase: MockSubscriptionPlanPriceUseCase(planPrice: planPrice),
            displayName: { _ in "Pro I" },
            locale: Locale(identifier: "en_US")
        )
    }
}

// MARK: - Test doubles

private struct MockUserBannerUseCase: UserBannerUseCaseProtocol {
    func banners(variant: Int, completion: @escaping @Sendable (Result<[BannerEntity], BannerErrorEntity>) -> Void) {
        completion(.success([]))
    }

    func dismissBanner(withBannerId bannerId: Int, completion: (@Sendable (Result<Void, BannerErrorEntity>) -> Void)?) {
        completion?(.success(()))
    }

    func bannerCategory(withBannerId bannerId: Int) -> UserBannerUseCase.BannerCategory {
        .undefined
    }
}

private final class MockDiscountBannerUseCase: HomeDiscountBannerUseCaseProtocol, @unchecked Sendable {
    private let plan: PlanEntity?
    private(set) var dismissedPlans: [PlanEntity] = []

    init(promotedPlan: PlanEntity? = nil) {
        plan = promotedPlan
    }

    func promotedPlan() async throws -> PlanEntity? { plan }

    func isDismissed(_ plan: PlanEntity) -> Bool { false }

    func dismiss(_ plan: PlanEntity) {
        dismissedPlans.append(plan)
    }
}
