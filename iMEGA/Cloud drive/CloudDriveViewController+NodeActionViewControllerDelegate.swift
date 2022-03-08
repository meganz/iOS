
extension CloudDriveViewController: NodeActionViewControllerDelegate {
    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, forNodes nodes: [MEGANode], from sender: Any) ->  () {
        switch action {
        case .download:
            nodes.forEach { $0.mnz_downloadNode() }
            setEditMode(false)
        case .copy:
            showBrowserNavigation(for: nodes, action: .copy)
        case .move:
            prepareToMoveNodes(nodes)
        case .moveToRubbishBin:
            guard let deleteBarButton = sender as? UIBarButtonItem else { return }
            deleteAction(sender: deleteBarButton)
            setEditMode(false)
        case .exportFile:
            let entityNodes = nodes.map { NodeEntity(node: $0) }
            ExportFileRouter(presenter: self, sender: sender).export(nodes: entityNodes)
            setEditMode(false)
        case .shareFolder:
            showShareFolderForNodes(nodes)
        case .shareLink:
            presentGetLinkVC(for: nodes)
            setEditMode(false)
        case .sendToChat:
            showSendToChat(nodes)
            setEditMode(false)
        default:
            break
        }
    }
}
