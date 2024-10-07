@testable import MEGA

final class MockHomeBannerRouter: HomeBannerRouterProtocol {
    private(set) var didTrigger_calledTimes = 0
    private(set) var lastTriggeredURL: URL?

    func didTrigger(from source: HomeBannerRouter.BannerTarget) {
        didTrigger_calledTimes += 1
        switch source {
        case .universalLink(let url):
            lastTriggeredURL = url
        }
    }
}
