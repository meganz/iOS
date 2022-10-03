import MEGADomain

final class BackupNodesValidator {
    private let inboxUseCase: InboxUseCaseProtocol
    private let nodes: [NodeEntity]
    private let presenter: UIViewController
    
    init(presenter: UIViewController, inboxUseCase: InboxUseCaseProtocol = InboxUseCase(inboxRepository: InboxRepository.newRepo, nodeRepository: NodeRepository.newRepo), nodes: [NodeEntity]) {
        self.presenter = presenter
        self.inboxUseCase = inboxUseCase
        self.nodes = nodes
    }
    
    func isAnyShareNodesBackupNodes() -> Bool {
        nodes.contains(where: inboxUseCase.isInboxNode)
    }
    
    func areAllShareNodesBackupNodes() -> Bool {
        nodes.allSatisfy({ inboxUseCase.isInboxNode($0) })
    }
    
    private func presentWarningAlert(title: String, message: String, completion: @escaping () -> Void) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        let continueAction = UIAlertAction(title: Strings.Localizable.yes, style: .default) { _ in
            completion()
        }
        alert.addAction(continueAction)
        alert.addAction(UIAlertAction(title: Strings.Localizable.cancel, style: .cancel))
        alert.preferredAction = continueAction
        
        presenter.present(alert, animated: true, completion: nil)
    }
    
    func showWarningAlertIfNeeded(completion: @escaping () -> Void) {
        if areAllShareNodesBackupNodes() {
            presentWarningAlert(title: Strings.Localizable.permissions,
                                message: Strings.Localizable.Mybackups.Share.Folder.Warning.message(nodes.count)) {
                completion()
            }
        } else if isAnyShareNodesBackupNodes() {
            presentWarningAlert(title: Strings.Localizable.permissions,
                                message: Strings.Localizable.Dialog.Share.Backup.Non.Backup.Folders.Warning.message) {
                completion()
            }
        } else {
            completion()
        }
    }
}
