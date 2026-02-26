import MEGAAppSDKRepo
import MEGADomain
import SwiftUI

// IOS-11343: Fetch banners and display them
@MainActor
final class PromotionalBannersWidgetViewModel: ObservableObject {
    @Published var bannerInputs: [PromotionBannerInput] = []

    private let bannerUseCase: any UserBannerUseCaseProtocol

    convenience init() {
        self.init(bannerUseCase: UserBannerUseCase(userBannerRepository: BannerRepository.newRepo))
    }

    package init(
        bannerUseCase: some UserBannerUseCaseProtocol
    ) {
        self.bannerUseCase = bannerUseCase
    }

    func onTask() async {
        await loadBanners()
    }

    func closeBanner(bannerIdentifier: Int) async {
        do {
            try await bannerUseCase.dismissBanner(withBannerId: bannerIdentifier)
            bannerInputs.removeAll { $0.id == bannerIdentifier }
        } catch {
            MEGALogError("[Home Promotional Banners] Could not dismiss banner with id \(bannerIdentifier). Error: \(error.localizedDescription)")
        }
    }

    private func loadBanners() async {
        do {
            let banners = try await bannerUseCase.banners(variant: 1).map(\.promotionalBannerInput)
            bannerInputs = banners
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
