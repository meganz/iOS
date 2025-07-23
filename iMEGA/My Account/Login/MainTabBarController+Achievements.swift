import MEGAAppPresentation

extension MainTabBarController {
    @objc func showAchievementsScreen() {
        guard MEGASdk.shared.isAchievementsEnabled else { return }

        if DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .navigationRevamp) {
            showAchievementsScreenRevamped()
        } else {
            showAchievementsScreenLegacy()
        }
    }

    private func showAchievementsScreenRevamped() {
        let menuTabIndex = TabManager.menuTabIndex()
        selectedIndex = menuTabIndex

        guard let navigationController = children[menuTabIndex] as? (any AccountMenuItemsNavigating) else {
            assertionFailure("AccountMenuItemsNavigating not found")
            return
        }

        navigationController.showAchievements()
    }

    private func showAchievementsScreenLegacy() {
        let homeTabIndex = TabManager.homeTabIndex()
        selectedIndex = homeTabIndex

        guard let navigationController = children[homeTabIndex] as? MEGANavigationController,
              let homeRouting = navigationController.viewControllers.first as? (any HomeRouting) else {
            assertionFailure("Home routing not found")
            return
        }
        
        homeRouting.showAchievements()
    }
}
