import MEGAAppSDKRepo

extension MainTabBarController {
    @objc func observeNodeUpdatesIfNeeded() {
        guard !isNavigationRevampEnabled else { return }
        MEGASdk.shared.add(self)
    }

    @objc func updateSharedItemsTabBadgeIfNeeded(_ nodeList: MEGANodeList) {
        let nodes = nodeList.toNodeArray()
        guard nodes.shareChangeTypeNodes().isNotEmpty else { return }
        setBadgeValueForSharedItemsIfNeeded()
    }
    
    @objc func setBadgeValueForSharedItemsIfNeeded() {
        guard !isNavigationRevampEnabled else { return }
        let unverifiedInShares = MEGASdk.shared.getUnverifiedInShares(.defaultAsc)
        let unverifiedOutShares = MEGASdk.shared.isContactVerificationWarningEnabled ? MEGASdk.shared.outShares(.defaultAsc)
            .toShareEntities()
            .first { share in
                share.sharedUserEmail != nil && !share.isVerified
            } : nil

        guard unverifiedOutShares != nil || unverifiedInShares.size > 0 else {
            setBadgeValue(nil, tabPosition: TabManager.sharedItemsTabIndex())
            return
        }
        setBadgeValue("⦁", tabPosition: TabManager.sharedItemsTabIndex())
    }
}
