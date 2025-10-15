@MainActor
protocol AdsVisibilityViewModelProtocol: AnyObject {
    func configureAdsVisibility()
}

@MainActor
protocol AdsVisibilityConfigurating {
    func configureAdsVisibility()
}

final class AdsVisibilityViewModel: AdsVisibilityViewModelProtocol {
    // Note: We need to use a closure to access the configurator because the configurator (aka UIApplication.mainTabBarRootViewController())
    // might not be available at the time this VM is created.
    private let configuratorProvider: () -> (any AdsVisibilityConfigurating)?
    
    init(configuratorProvider: @escaping () -> (any AdsVisibilityConfigurating)?) {
        self.configuratorProvider = configuratorProvider
    }
    
    func configureAdsVisibility() {
        configuratorProvider()?.configureAdsVisibility()
    }
}

extension MainTabBarController: AdsVisibilityConfigurating {}
