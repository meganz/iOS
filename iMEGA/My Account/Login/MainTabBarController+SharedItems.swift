extension MainTabBarController {
    @objc func updateSharedItemsTabBadgeIfNeeded(_ nodeList: MEGANodeList) {
        let nodes = nodeList.toNodeArray()
        guard nodes.shareChangeTypeNodes().isNotEmpty else { return }
        setBadgeValueForSharedItems()
    }
    
    @objc func setBadgeValueForSharedItems() {
        let unverifiedInShares = MEGASdk.shared.getUnverifiedInShares(.defaultAsc)
        let unverifiedOutShares = MEGASdk.shared.isContactVerificationWarningEnabled ? MEGASdk.shared.outShares(.defaultAsc)
            .toShareEntities()
            .first { share in
                share.sharedUserEmail != nil && !share.isVerified
            } : nil

        guard unverifiedOutShares != nil || unverifiedInShares.size > 0 else {
            setBadgeValue(nil, tabPosition: TabType.sharedItems.rawValue)
            return
        }
        setBadgeValue("⦁", tabPosition: TabType.sharedItems.rawValue)
    }
}
