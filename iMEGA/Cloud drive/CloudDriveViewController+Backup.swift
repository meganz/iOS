
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
        let setupBackupAlertController = UIAlertController(title: Strings.Localizable.Dialog.Backup.Setup.title,
                                                           message: Strings.Localizable.Dialog.Backup.Setup.message,
                                                           preferredStyle: .alert)
        setupBackupAlertController.addAction(UIAlertAction(title: Strings.Localizable.ok, style: .default, handler: nil))
        
        present(setupBackupAlertController, animated: true, completion: nil)
    }
}
