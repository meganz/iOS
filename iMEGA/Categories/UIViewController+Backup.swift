
extension UIViewController {
    func backup(node: MEGANode, action: BackupAction, confirmAction: BackupAction, confirmActionCompletion: @escaping () -> Void) {
        
        let infoAlert = CustomModalBackupAlertRouter(backupAlertData: configureBackupAlertFor(node: node, action: action),
                                                     presenter: UIApplication.mnz_presentingViewController(),
                                                     actionCompletion:  {
            
            let confirmAlert = CustomModalBackupAlertRouter(backupAlertData: self.configureBackupAlertFor(node: node, action: confirmAction),
                                                            presenter: UIApplication.mnz_presentingViewController(),
                                                            actionCompletion: confirmActionCompletion)
            confirmAlert.start()
        })
        
        infoAlert.start()
    }
    
    private func configureBackupAlertFor(node: MEGANode, action: BackupAction) -> BackupAlertConfiguration {
        switch action {
        case .move:
            return BackupAlertConfiguration(node: node,
                                            title: String(format: NSLocalizedString("dialog.backup.folder.location.warning.title", comment: ""), node.name ?? ""),
                                            description: node.isBackupRootNode() ?
                                                                NSLocalizedString("dialog.root.backup.folder.location.warning.message", comment: "") :
                                                                NSLocalizedString("dialog.backup.folder.location.warning.message", comment: ""),
                                            actionTitle: NSLocalizedString("continue", comment: ""))
            
        case .moveToRubbishBin:
            return BackupAlertConfiguration(node: node,
                                            title: String(format: NSLocalizedString("dialog.delete.backup.folder.warning.title", comment: ""), node.name ?? ""),
                                            description: node.isBackupRootNode() ?
                                                                NSLocalizedString("dialog.delete.root.backup.folder.warning.message", comment: "") :
                                                                NSLocalizedString("dialog.delete.backup.folder.warning.message", comment: ""),
                                            actionTitle: NSLocalizedString("continue", comment: ""))
        case .addFolder:
            return BackupAlertConfiguration(node: node,
                                            title: String(format: NSLocalizedString("dialog.add.items.backup.folder.warning.title", comment: ""), node.name ?? ""),
                                            description: NSLocalizedString("dialog.add.items.backup.folder.warning.message", comment: ""),
                                            actionTitle: NSLocalizedString("continue", comment: ""))
        case .confirmMove:
            let placeholder = node.isBackupRootNode() ?
                                                    NSLocalizedString("dialog.move.backup.placeholder", comment: "") :
                                                    NSLocalizedString("dialog.disable.backup.placeholder", comment: "")
            return BackupAlertConfiguration(node: node,
                                            title: String(format: NSLocalizedString("dialog.backup.folder.location.warning.title", comment: ""), node.name ?? ""),
                                            description: String(format: NSLocalizedString("dialog.backup.warning.confirm.message", comment: ""), placeholder),
                                            actionTitle: NSLocalizedString("move", comment: ""),
                                            confirmPlaceholder: placeholder)
        case .confirmMoveToRubbishBin:
            let placeholder = node.isBackupRootNode() ?
                                                    NSLocalizedString("dialog.disable.backup.placeholder", comment: "") :
                                                    NSLocalizedString("dialog.delete.backup.placeholder", comment: "")
            return BackupAlertConfiguration(node: node,
                                            title: String(format: NSLocalizedString("dialog.delete.backup.folder.warning.title", comment: ""), node.name ?? ""),
                                            description: String(format: NSLocalizedString("dialog.backup.warning.confirm.message", comment: ""), placeholder),
                                            actionTitle: NSLocalizedString("dialog.delete.backup.action.title", comment: ""),
                                            confirmPlaceholder: placeholder)
            
        case .confirmAddFolder:
            return BackupAlertConfiguration(node: node,
                                            title: String(format: NSLocalizedString("dialog.add.items.backup.folder.warning.title", comment: ""), node.name ?? ""),
                                            description: String(format: NSLocalizedString("dialog.backup.warning.confirm.message", comment: ""), NSLocalizedString("dialog.disable.backup.placeholder", comment: "")),
                                            actionTitle: NSLocalizedString("dialog.add.items.backup.action.title", comment: ""),
                                            confirmPlaceholder: NSLocalizedString("dialog.disable.backup.placeholder", comment: ""))
        }
    }
}
