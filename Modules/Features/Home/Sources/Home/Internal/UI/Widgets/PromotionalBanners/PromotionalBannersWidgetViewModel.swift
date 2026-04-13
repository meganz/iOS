import MEGAAppSDKRepo
import MEGADomain
import SwiftUI

@MainActor
final class PromotionalBannersWidgetViewModel: ObservableObject {
    @Published var bannerViewModels: [PromotionalBannerViewModel] = []

    private let bannerUseCase: any UserBannerUseCaseProtocol
    private let cache: PromotionalBannerCache

    convenience init() {
        self.init(
            bannerUseCase: UserBannerUseCase(userBannerRepository: BannerRepository.newRepo),
            cache: .shared
        )
    }

    package init(
        bannerUseCase: some UserBannerUseCaseProtocol,
        cache: PromotionalBannerCache = .shared
    ) {
        self.bannerUseCase = bannerUseCase
        self.cache = cache
        // Make use of previously fetched cache and display them to the UI immediately
        // instead of having to re-fetch them which cause snappy UI glitch each time
        // the view is re-render
        self.bannerViewModels = cache.cachedViewModels
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
}

extension BannerEntity {
    var promotionalBannerInput: PromotionBannerInput {
        PromotionBannerInput(id: identifier, title: title, actionTitle: button, imageURL: imageURL, backgroundURL: backgroundImageURL, link: url)
    }
}
