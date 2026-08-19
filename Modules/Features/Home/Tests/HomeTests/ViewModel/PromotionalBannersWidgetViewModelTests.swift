@testable import Home
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

    // MARK: - Helpers

    private func makeSUT(tracker: MockTracker) -> PromotionalBannersWidgetViewModel {
        PromotionalBannersWidgetViewModel(
            bannerUseCase: MockUserBannerUseCase(),
            discountBannerUseCase: MockDiscountBannerUseCase(),
            cache: PromotionalBannerCache(accountUseCase: MockAccountUseCase()),
            tracker: tracker
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

private struct MockDiscountBannerUseCase: DiscountBannerUseCaseProtocol {
    func promotedPlan() async throws -> PlanEntity? { nil }

    func isDismissed(_ plan: PlanEntity) -> Bool { false }

    func dismiss(_ plan: PlanEntity) {}
}
