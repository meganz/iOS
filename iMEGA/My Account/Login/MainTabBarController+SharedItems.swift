extension MainTabBarController {
    @objc func setBadgeValueForSharedItems() {
        let unverifiedInShares = MEGASdk.shared.getUnverifiedInShares(.defaultAsc)
        let unverifiedOutShares = MEGASdk.shared.outShares(.defaultAsc)
            .toShareEntities()
            .first { share in
                share.sharedUserEmail != nil && !share.isVerified
            }
        
        guard unverifiedOutShares != nil || unverifiedInShares.size.intValue > 0 else {
            setBadgeValue(nil, tabPosition: TabType.sharedItems.rawValue)
            return
        }
        setBadgeValue("⦁", tabPosition: TabType.sharedItems.rawValue)
    }
}
