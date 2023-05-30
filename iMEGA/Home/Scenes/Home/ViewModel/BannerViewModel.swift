import Foundation

protocol HomeBannerViewModelInputs {

    func viewIsReady()

    func dismissBanner(withBannerId bannerId: Int)

    func didSelectBanner(actionURL: URL?)
}

protocol HomeBannerViewModelOutputs {

    var state: HomeBannerDisplayModel { get }
}

protocol HomeBannerViewModelType {

    var inputs: HomeBannerViewModelInputs { get }

    var outputs: HomeBannerViewModelOutputs { get }

    var notifyUpdate: ((HomeBannerViewModelOutputs) -> Void)? { get set }
}

final class HomeBannerViewModel: HomeBannerViewModelType {

    var inputs: HomeBannerViewModelInputs { self }

    var outputs: HomeBannerViewModelOutputs { self }

    var notifyUpdate: ((HomeBannerViewModelOutputs) -> Void)?
    
    // MARK: - Router

    private var router: HomeBannerRouter

    // MARK: - State
    
    private var displayingBanners: [HomeBannerDisplayModel.Banner] = []
    
    // MARK: - Use Case

    private let userBannerUseCase: UserBannerUseCaseProtocol

    init(userBannerUseCase: UserBannerUseCaseProtocol, router: HomeBannerRouter) {
        self.userBannerUseCase = userBannerUseCase
        self.router = router
    }
}

struct HomeBannerDisplayModel {

    let banners: [Banner]
    
    struct Banner {
        let identifier: Int
        let title: String
        let description: String
        let image: URL
        let backgroundImage: URL
        let actionURL: URL?
    }
}

extension HomeBannerViewModel: HomeBannerViewModelInputs {

    func viewIsReady() {
        userBannerUseCase.banners { [weak self] bannersResult in
            guard let self = self else { return }

            switch bannersResult {
            case .failure(let error): MEGALogError(error.localizedDescription)
            case .success(let banners):
                self.displayingBanners = banners.map { bannerEntity -> HomeBannerDisplayModel.Banner in
                    HomeBannerDisplayModel.Banner(
                        identifier: bannerEntity.identifier,
                        title: bannerEntity.title,
                        description: bannerEntity.description,
                        image: bannerEntity.imageURL,
                        backgroundImage: bannerEntity.backgroundImageURL,
                        actionURL: bannerEntity.url
                    )
                }
                if !self.displayingBanners.isEmpty {
                    self.notifyUpdate?(self)
                }
            }
        }
    }

    func dismissBanner(withBannerId bannerId: Int) {
        userBannerUseCase.dismissBanner(withBannerId: bannerId, completion: nil)
    }

    func didSelectBanner(actionURL: URL?) {
        guard let actionURL = actionURL else {
            // Should handle action URL missiong error
            return
        }
        router.didTrigger(from: .universalLink(actionURL))
    }
}

extension HomeBannerViewModel: HomeBannerViewModelOutputs {
    var state: HomeBannerDisplayModel {
        HomeBannerDisplayModel(banners: displayingBanners)
    }
}
