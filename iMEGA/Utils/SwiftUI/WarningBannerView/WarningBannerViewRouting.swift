@MainActor
protocol WarningBannerViewRouting {
    func goToSettings()
    func presentUpgradeScreen()
    func openURL(_ url: URL)
}
