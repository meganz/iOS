import MEGAAppSDKRepo
import MEGADomain
import SwiftUI

// IOS-11343: Fetch banners and display them
@MainActor
final class PromotionalBannersWidgetViewModel: ObservableObject {
    @Published var bannerInputs: [PromotionBannerInput] = []

    private let bannerUseCase: any UserBannerUseCaseProtocol

    init(
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
            MEGALogError("Could not dismiss banner with id \(bannerIdentifier)")
        }
    }

    private func loadBanners() async {
        do {
            let banners = try await bannerUseCase.banners(variant: 1).map(\.promotionalBannerInput)
            bannerInputs = banners
        } catch {
            MEGALogError("Could not loead banners")
        }
    }
}

extension BannerEntity {
    var promotionalBannerInput: PromotionBannerInput {
        PromotionBannerInput(id: identifier, title: title, actionTitle: button, imageURL: imageURL, backgroundURL: backgroundImageURL, link: url)
    }
}
