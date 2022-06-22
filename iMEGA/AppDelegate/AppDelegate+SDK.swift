import Foundation

extension AppDelegate {
    @objc func postNodeUpdatesNotifications(for nodeList: MEGANodeList) {
        let nodes = nodeList.toNodeArray()
        postFavouriteUpdatesNotification(for: nodes)
    }
    
    private func postFavouriteUpdatesNotification(for nodes: [MEGANode]) {
        let updatedNodes = nodes.modifiedFavourites().toNodeEntities()
        if !updatedNodes.isEmpty {
            NotificationCenter.default.post(name: .didPhotoFavouritesChange, object: updatedNodes)
        }
    }
}
