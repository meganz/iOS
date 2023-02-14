extension MainTabBarController {
    @objc func setBadgeValueForSharedItems() {
        let unverifiedOutShares = MEGASdk.shared.getUnverifiedOutShares(.defaultAsc)
        let unverifiedInShares = MEGASdk.shared.getUnverifiedInShares(.defaultAsc)
        let shareCount = unverifiedInShares.size.intValue + unverifiedOutShares.size.intValue
        
        guard shareCount > 0 else {
            setBadgeValue(nil, tabPosition: TabType.sharedItems.rawValue)
            return
        }
        setBadgeValue("⦁", tabPosition: TabType.sharedItems.rawValue)
    }
}
