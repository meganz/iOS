struct WarningBannerViewRouter: WarningBannerViewRouting {
    weak var navigationController: UINavigationController?
    
    func goToSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsUrl)
    }
    
    func presentUpgradeScreen() {
        UpgradeSubscriptionRouter(
            presenter: navigationController)
        .showUpgradeAccount()
    }

    func openURL(_ url: URL) {
        (url as NSURL).mnz_presentSafariViewController()
    }
}
