import Foundation
import MEGADomain

protocol HomeBannerViewModelInputs {

    func viewIsReady()

    func dismissBanner(withBannerId bannerId: Int)

    func didSelectBanner(actionURL: URL?)
}

protocol HomeBannerViewModelOutputs {

    var state: HomeBannerDisplayModel { get }
}

protocol HomeBannerViewModelType {

    var inputs: any HomeBannerViewModelInputs { get }

    var outputs: any HomeBannerViewModelOutputs { get }

    var notifyUpdate: ((any HomeBannerViewModelOutputs) -> Void)? { get set }
}

final class HomeBannerViewModel: HomeBannerViewModelType {

    var inputs: any HomeBannerViewModelInputs { self }

    var outputs: any HomeBannerViewModelOutputs { self }

    var notifyUpdate: ((any HomeBannerViewModelOutputs) -> Void)?
    
    // MARK: - Router

    private var router: any HomeBannerRouterProtocol

    // MARK: - State
    
    private var displayingBanners: [HomeBannerDisplayModel.Banner] = []
    
    // MARK: - Use Case

    private let userBannerUseCase: any UserBannerUseCaseProtocol

    init(
        userBannerUseCase: some UserBannerUseCaseProtocol,
        router: some HomeBannerRouterProtocol
    ) {
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
            guard let self else { return }

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
