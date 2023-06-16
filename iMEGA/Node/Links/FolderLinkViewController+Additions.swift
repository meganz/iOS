import Foundation

extension FolderLinkViewController {
    @objc func containsOnlyMediaFiles() -> Bool {
        guard FeatureFlagProvider().isFeatureFlagEnabled(for: .folderLinkMediaDiscovery) else {
            return false
        }
        return nodesArray.toNodeEntities().notContains {
            $0.mediaType == nil
        }
    }
    
    @objc func showMediaDiscovery() {
        guard let parentNode = MEGASdk.sharedFolderLinkSdk.rootNode else { return }
        MediaDiscoveryRouter(viewController: self, parentNode: parentNode, isFolderLink: true).start()
    }
}
