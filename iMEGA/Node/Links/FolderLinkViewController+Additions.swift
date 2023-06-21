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
        var link = publicLinkString
        if let linkEncryptedString {
            link = linkEncryptedString
        }
        guard let parentNode = MEGASdk.sharedFolderLinkSdk.rootNode,
              let link else { return }
        
        MediaDiscoveryRouter(viewController: self, parentNode: parentNode, folderLink: link).start()
    }
}
