import Foundation

final class HomeBannerRouter {

    weak var navigationController: UINavigationController?

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func didTrigger(from source: BannerTarget) {
        switch source {
        case .universalLink(let url):
            MEGALinkManager.linkURL = url
            MEGALinkManager.processLinkURL(url)
        }
    }

    // MARK: - Event Source

    enum BannerTarget {

        case universalLink(URL)
    }
}
