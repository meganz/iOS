import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import SwiftUI

@MainActor
final class PromotionalBannersWidgetViewModel: ObservableObject {
    @Published var bannerViewModels: [PromotionalBannerViewModel] = []

    private let bannerUseCase: any UserBannerUseCaseProtocol
    private let cache: PromotionalBannerCache
    private let tracker: any AnalyticsTracking

    convenience init() {
        self.init(
            bannerUseCase: UserBannerUseCase(userBannerRepository: BannerRepository.newRepo),
            cache: .shared,
            tracker: DIContainer.tracker
        )
    }

    package init(
        bannerUseCase: some UserBannerUseCaseProtocol,
        cache: PromotionalBannerCache = .shared,
        tracker: some AnalyticsTracking
    ) {
        self.bannerUseCase = bannerUseCase
        self.cache = cache
        // Make use of previously fetched cache and display them to the UI immediately
        // instead of having to re-fetch them which cause snappy UI glitch each time
        // the view is re-rendered
        self.bannerViewModels = cache.cachedViewModels
        self.tracker = tracker
    }

    func onTask() async {
        await loadBanners()
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
