import MEGAAppPresentation

extension MainTabBarController {
    @objc func showAchievementsScreen() {
        guard MEGASdk.shared.isAchievementsEnabled else { return }
        
        let menuTabIndex = TabManager.menuTabIndex()
        selectedIndex = menuTabIndex
        
        guard let navigationController = children[menuTabIndex] as? (any AccountMenuItemsNavigating) else {
            assertionFailure("AccountMenuItemsNavigating not found")
            return
        }
        
        navigationController.showAchievements()
    }
}
