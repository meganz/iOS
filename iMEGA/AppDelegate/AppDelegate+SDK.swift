import ContentLibraries
import Foundation
import MEGADomain
import MEGARepo
import MEGASDKRepo

extension AppDelegate {
    @objc func postNodeUpdatesNotifications(for nodeList: MEGANodeList) {
        let nodes = nodeList.toNodeArray()
        postFavouriteUpdatesNotification(for: nodes)
    }
    
    @objc func removeCachedFilesIfNeeded(for nodeList: MEGANodeList) {
        let removedNodes = nodeList.toNodeEntities().filter { $0.isRemoved }
        if removedNodes.isNotEmpty {
            let nodesRemovedUseCase = NodesRemovedUseCase(
                thumbnailRepository: ThumbnailRepository.newRepo,
                fileRepository: FileSystemRepository.newRepo,
                removedNodes: removedNodes
            )
            Task {
                await nodesRemovedUseCase.removeCachedFiles()
            }
        }
    }
    
    private func postFavouriteUpdatesNotification(for nodes: [MEGANode]) {
        let updatedNodes = nodes.modifiedFavourites().toNodeEntities()
        if !updatedNodes.isEmpty {
            NotificationCenter.default.post(name: .didPhotoFavouritesChange, object: updatedNodes)
        }
    }
}
