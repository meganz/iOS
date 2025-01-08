protocol AdsSlotDisplayable {
    func configureAdsVisibility()
}

extension AdsSlotDisplayable where Self: UIViewController {
    func configureAdsVisibility() {
        guard let mainTabBar = UIApplication.mainTabBarRootViewController() as? MainTabBarController else { return }
        mainTabBar.configureAdsVisibility()
    }
}
