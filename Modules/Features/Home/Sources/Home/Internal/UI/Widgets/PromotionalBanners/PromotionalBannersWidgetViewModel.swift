import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGASwift
import SwiftUI

@MainActor
final class PromotionalBannersWidgetViewModel: ObservableObject {
    @Published var bannerViewModels: [PromotionalBannerViewModel] = []
    @Published private(set) var discountBanner: DiscountBannerContent?

    private let bannerUseCase: any UserBannerUseCaseProtocol
    private let discountBannerUseCase: any HomeDiscountBannerUseCaseProtocol
    private let discountBannerMapper: DiscountBannerContentMapper
    private let cache: PromotionalBannerCache
    private let tracker: any AnalyticsTracking
    private let planPurchases: AnyAsyncSequence<Void>
    private var monitorPlanPurchasesTask: Task<Void, Never>?

    convenience init(promotedPlanProvider: @escaping @Sendable () async throws -> PlanEntity?) {
        self.init(
            bannerUseCase: UserBannerUseCase(userBannerRepository: BannerRepository.newRepo),
            discountBannerUseCase: HomeDiscountBannerUseCase(promotedPlanProvider: promotedPlanProvider),
            cache: .shared,
            tracker: DIContainer.tracker
        )
    }

    package init(
        bannerUseCase: some UserBannerUseCaseProtocol,
        discountBannerUseCase: some HomeDiscountBannerUseCaseProtocol,
        discountBannerMapper: DiscountBannerContentMapper = DiscountBannerContentMapper(),
        cache: PromotionalBannerCache = .shared,
        tracker: some AnalyticsTracking,
        planPurchases: AnyAsyncSequence<Void> = NotificationCenter.purchaseSuccesses()
    ) {
        self.bannerUseCase = bannerUseCase
        self.discountBannerUseCase = discountBannerUseCase
        self.discountBannerMapper = discountBannerMapper
        self.cache = cache
        self.planPurchases = planPurchases
        // Make use of previously fetched cache and display them to the UI immediately
        // instead of having to re-fetch them which cause snappy UI glitch each time
        // the view is re-rendered
        self.bannerViewModels = cache.cachedViewModels
        self.tracker = tracker
        if let cached = cache.cachedPromotedPlan, !discountBannerUseCase.isDismissed(cached) {
            discountBanner = discountBannerMapper.map(cached)
        }

        // Listen for purchases in init() instead of .task() because purchases can happen in other
        // screens of the app
        listenToPlanPurchases()
    }

    deinit {
        monitorPlanPurchasesTask?.cancel()
    }

    func onTask() async {
        async let remoteBanners: Void = loadBanners()
        async let discountBanner: Void = loadDiscountBanner()
        _ = await (remoteBanners, discountBanner)
    }

    /// Hides the discount banner as soon as a purchase succeeds, rather than leaving the offer on
    /// screen until the offer is next re-fetched.
    private func listenToPlanPurchases() {
        monitorPlanPurchasesTask?.cancel()
        monitorPlanPurchasesTask = Task { @MainActor [weak self, planPurchases] in
            for await _ in planPurchases {
                self?.dismissDiscountBannerAfterPurchase()
            }
        }
    }

    /// Records the dismissal the same way closing the banner does, so a campaign the user has converted
    /// on stays away even if the offer is briefly still on the account. The cached plan is read before it
    /// is cleared, otherwise there would be nothing left to record against.
    private func dismissDiscountBannerAfterPurchase() {
        if let plan = cache.cachedPromotedPlan {
            discountBannerUseCase.dismiss(plan)
        }
        cache.clearPromotedPlan()
        discountBanner = nil
    }

    func trackDiscountBannerDisplayed() {
        tracker.trackAnalyticsEvent(with: HomeSubscriptionOfferBannerDisplayedEvent())
    }

    func trackDiscountBannerTapped() {
        tracker.trackAnalyticsEvent(with: HomeSubscriptionOfferBannerPressedEvent())
    }

    func closeDiscountBanner() {
        tracker.trackAnalyticsEvent(with: HomeSubscriptionOfferBannerDismissButtonPressedEvent())
        if let plan = cache.cachedPromotedPlan {
            discountBannerUseCase.dismiss(plan)
        } else {
            MEGALogError("[Home Promotional Banners] Discount banner closed with no cached plan; dismissal not persisted")
        }
        discountBanner = nil
    }

    func closeBanner(bannerIdentifier: Int) async {
        do {
            try await bannerUseCase.dismissBanner(withBannerId: bannerIdentifier)
            bannerViewModels.removeAll { $0.input.id == bannerIdentifier }
            cache.removeBanner(withId: bannerIdentifier)
        } catch {
            MEGALogError("[Home Promotional Banners] Could not dismiss banner with id \(bannerIdentifier). Error: \(error.localizedDescription)")
        }
    }

    func trackBannerTapped(url: URL) {
        guard let event = tapAnalyticsEvent(for: url) else { return }
        tracker.trackAnalyticsEvent(with: event)
    }

    func trackBannerClosed(url: URL?) {
        guard let url, let event = closeAnalyticsEvent(for: url) else { return }
        tracker.trackAnalyticsEvent(with: event)
    }

    private func loadBanners() async {
        do {
            let banners = try await bannerUseCase.banners(variant: 1).map(\.promotionalBannerInput)
            guard banners.map(\.id) != cache.cachedViewModels.map(\.input.id) else { return }
            cache.update(with: banners.map { PromotionalBannerViewModel(input: $0) })
            bannerViewModels = cache.cachedViewModels
        } catch {
            MEGALogError("[Home Promotional Banners] Could not load banners. Error: \(error.localizedDescription)")
        }
    }

    private func loadDiscountBanner() async {
        do {
            // There is no offer for this user, so hide any old banner we are still showing,
            // for example one whose offer has already ended while the app was open.
            guard let plan = try await discountBannerUseCase.promotedPlan() else {
                cache.clearPromotedPlan()
                discountBanner = nil
                return
            }
            cache.updatePromotedPlan(plan)
            discountBanner = discountBannerMapper.map(plan)
        } catch {
            MEGALogError("[Home Promotional Banners] Could not load promoted plan. Error: \(error.localizedDescription)")
        }
    }

    private func tapAnalyticsEvent(for url: URL) -> (any EventIdentifier)? {
        switch url.bannerType {
        case .vpn: VpnSmartBannerItemSelectedEvent()
        case .pwm: PwmSmartBannerItemSelectedEvent()
        case .transferIt: TransferItSmartBannerItemSelectedEvent()
        case .unknown: nil
        }
    }

    private func closeAnalyticsEvent(for url: URL) -> (any EventIdentifier)? {
        switch url.bannerType {
        case .vpn: VpnBannerCloseButtonPressedEvent()
        case .pwm: PwmBannerCloseButtonPressedEvent()
        case .transferIt: TransferItBannerCloseButtonPressedEvent()
        case .unknown: nil
        }
    }
}

extension BannerEntity {
    var promotionalBannerInput: PromotionBannerInput {
        PromotionBannerInput(id: identifier, title: title, actionTitle: button, imageURL: imageURL, backgroundURL: backgroundImageURL, link: url)
    }
}

private extension URL {
    enum BannerType {
        case vpn, pwm, transferIt, unknown
    }

    var bannerType: BannerType {
        if host == "vpn.mega.nz" {
            .vpn
        } else if host == "pwm.mega.nz" {
            .pwm
        } else if absoluteString.contains("transfer-it") {
            .transferIt
        } else {
            .unknown
        }
    }
}
