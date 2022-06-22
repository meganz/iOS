
extension CloudDriveViewController: NodeActionViewControllerDelegate {
    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, forNodes nodes: [MEGANode], from sender: Any) ->  () {
        switch action {
        case .download:
            TransfersWidgetViewController.sharedTransfer().bringProgressToFrontKeyWindowIfNeeded()
            let transfers = nodes.map { CancellableTransfer(handle: $0.handle, path: Helper.relativePathForOffline(), name: nil, appData: nil, priority: false, isFile: $0.isFile(), type: .download) }
            CancellableTransferRouter(presenter: self, transfers: transfers, transferType: .download).start()
            setEditMode(false)
        case .copy:
            showBrowserNavigation(for: nodes, action: .copy)
        case .move:
            prepareToMoveNodes(nodes)
        case .moveToRubbishBin:
            guard let deleteBarButton = sender as? UIBarButtonItem else { return }
            deleteAction(sender: deleteBarButton)
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
        case .removeLink:
            removeLinksForNodes(nodes)
            setEditMode(false)
        default:
            break
        }
    }
}
