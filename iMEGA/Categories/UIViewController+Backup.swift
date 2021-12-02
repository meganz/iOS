
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
                                            title: Strings.Localizable.Dialog.Backup.Folder.Location.Warning.title(node.name ?? ""),
                                            description: node.isBackupRootNode() ?
                                                                Strings.Localizable.Dialog.Root.Backup.Folder.Location.Warning.message :
                                                                Strings.Localizable.Dialog.Backup.Folder.Location.Warning.message,
                                            actionTitle: Strings.Localizable.continue)
            
        case .moveToRubbishBin:
            return BackupAlertConfiguration(node: node,
                                            title: Strings.Localizable.Dialog.Delete.Backup.Folder.Warning.title(node.name ?? ""),
                                            description: node.isBackupRootNode() ?
                                                                Strings.Localizable.Dialog.Delete.Root.Backup.Folder.Warning.message:
                                                                Strings.Localizable.Dialog.Delete.Backup.Folder.Warning.message,
                                            actionTitle: Strings.Localizable.continue)
        case .addFolder:
            return BackupAlertConfiguration(node: node,
                                            title: Strings.Localizable.Dialog.Add.Items.Backup.Folder.Warning.title(node.name ?? ""),
                                            description: Strings.Localizable.Dialog.Add.Items.Backup.Folder.Warning.message,
                                            actionTitle: Strings.Localizable.continue)
        case .confirmMove:
            let placeholder = node.isBackupRootNode() ?
                                                    Strings.Localizable.Dialog.Move.Backup.placeholder :
                                                    Strings.Localizable.Dialog.Disable.Backup.placeholder
            return BackupAlertConfiguration(node: node,
                                            title: Strings.Localizable.Dialog.Backup.Folder.Location.Warning.title(node.name ?? ""),
                                            description: Strings.Localizable.Dialog.Backup.Warning.Confirm.message(placeholder),
                                            actionTitle: Strings.Localizable.move,
                                            confirmPlaceholder: placeholder)
        case .confirmMoveToRubbishBin:
            let placeholder = node.isBackupRootNode() ?
                                                    Strings.Localizable.Dialog.Disable.Backup.placeholder :
                                                    Strings.Localizable.Dialog.Delete.Backup.placeholder
            return BackupAlertConfiguration(node: node,
                                            title: Strings.Localizable.Dialog.Delete.Backup.Folder.Warning.title(node.name ?? ""),
                                            description: Strings.Localizable.Dialog.Backup.Warning.Confirm.message(placeholder),
                                            actionTitle: Strings.Localizable.Dialog.Delete.Backup.Action.title,
                                            confirmPlaceholder: placeholder)
            
        case .confirmAddFolder:
            return BackupAlertConfiguration(node: node,
                                            title: Strings.Localizable.Dialog.Add.Items.Backup.Folder.Warning.title(node.name ?? ""),
                                            description: Strings.Localizable.Dialog.Backup.Warning.Confirm.message(Strings.Localizable.Dialog.Disable.Backup.placeholder),
                                            actionTitle: Strings.Localizable.Dialog.Add.Items.Backup.Action.title,
                                            confirmPlaceholder: Strings.Localizable.Dialog.Disable.Backup.placeholder)
        }
    }
}
