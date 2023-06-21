import Foundation
import MEGAPresentation

extension FolderLinkViewController {
    @objc func containsMediaFiles() -> Bool {
        guard DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .folderLinkMediaDiscovery) else {
            return false
        }
        return nodesArray.toNodeEntities().contains {
            $0.mediaType != nil
        }
    }
    
    @objc func showMediaDiscovery() {
        var link = publicLinkString
        if let linkEncryptedString {
            link = linkEncryptedString
        }
        guard let parentNode, let link else { return }
        MediaDiscoveryRouter(viewController: self, parentNode: parentNode, folderLink: link).start()
    }
}
