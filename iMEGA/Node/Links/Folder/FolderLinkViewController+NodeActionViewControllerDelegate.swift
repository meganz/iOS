import Foundation

extension FolderLinkViewController: NodeActionViewControllerDelegate {
    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, for node: MEGANode, from sender: Any) {
        switch action {
        case .download:
            selectedNodesArray = [node]
            if selectedNodesArray?.count != 0,
               let selectedNodesArray = selectedNodesArray as? [MEGANode] {
                download(selectedNodesArray)
            } else {
                guard let parentNode = parentNode else { return }
                download([parentNode])
            }
            setEditMode(false)
        case .import:
            if node.handle != parentNode?.handle {
                selectedNodesArray = [node]
            }
            importFromFiles()
        case .select:
            select()
        case .shareLink:
            showShareLink(from: moreBarButtonItem)
        case .saveToPhotos:
            saveToPhotos(nodes: [node.toNodeEntity()])
        case .sendToChat:
            showSendToChat()
        case .mediaDiscovery:
            showMediaDiscovery()
        default:
            break
        }
    }
}
