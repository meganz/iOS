struct WarningBannerViewRouter: WarningBannerViewRouting {
    weak var navigationController: UINavigationController?
    
    func goToSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(settingsUrl) else {
            return
        }
        UIApplication.shared.open(settingsUrl)
    }
    
    func presentUpgradeScreen() {
        UpgradeSubscriptionRouter(
            presenter: navigationController)
        .showUpgradeAccount()
    }
}
