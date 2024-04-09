import MEGAL10n
import MEGASDKRepo

extension CloudDriveViewController {
    @IBAction func deleteAction(sender: UIBarButtonItem) {
        guard let selectedNodes = selectedNodesArray as? [MEGANode] else {
            return
        }
        
        switch displayMode {
        case .cloudDrive:
            viewModel.dispatch(.moveToRubbishBin(selectedNodes))
        case .rubbishBin:
            confirmDeleteActionFiles(selectedNodes.contentCounts().fileCount,
                                     andFolders: selectedNodes.contentCounts().folderCount)
        default: break
        }
    }
    
    @objc func moveToRubbishBin(for node: MEGANode) {
        guard MEGASdk.shared.rubbishNode != nil else {
            self.dismiss(animated: true)
            return
        }
        viewModel.dispatch(.moveToRubbishBin([node]))
    }
}
