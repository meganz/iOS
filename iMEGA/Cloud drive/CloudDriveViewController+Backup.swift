
extension CloudDriveViewController {
    @objc func moveBackupNode(_ node: MEGANode, completion: @escaping () -> Void) {
        backup(node: node, action: .move, confirmAction: .confirmMove) {
            completion()
        }
    }
    
    @objc func moveToRubbishBinBackupNode(_ node: MEGANode, completion: @escaping () -> Void) {
        backup(node: node, action: .moveToRubbishBin, confirmAction: .confirmMoveToRubbishBin) {
            completion()
        }
    }
    
    @objc func addItemToBackupNode(_ node: MEGANode, completion: @escaping () -> Void) {
        backup(node: node, action: .addFolder, confirmAction: .confirmAddFolder) {
            completion()
        }
    }
    
    @objc func showSetupBackupAlert() {
        let setupBackupAlertController = UIAlertController(title: NSLocalizedString("dialog.backup.setup.title", comment: ""),
                                                           message: NSLocalizedString("dialog.backup.setup.message", comment: ""),
                                                           preferredStyle: .alert)
        setupBackupAlertController.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default, handler: nil))
        
        present(setupBackupAlertController, animated: true, completion: nil)
    }
}
