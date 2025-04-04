import Combine
import MEGAAppSDKRepo
import MEGADomain
import MEGAL10n

final class BackupNodesValidator {
    private let backupsUseCase: any BackupsUseCaseProtocol
    private let nodes: [NodeEntity]
    private let presenter: UIViewController
    private var inProgress = false
    private var inProgressSubscription: AnyCancellable?
    
    init(presenter: UIViewController, backupsUseCase: any BackupsUseCaseProtocol = BackupsUseCase(backupsRepository: BackupsRepository.newRepo, nodeRepository: NodeRepository.newRepo), nodes: [NodeEntity]) {
        self.presenter = presenter
        self.backupsUseCase = backupsUseCase
        self.nodes = nodes
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
    
    private func sharedBackupNodes() -> [NodeEntity] {
        nodes.filter {
            backupsUseCase.isBackupNode($0)
        }
    }

    private func showProgressHUDIfNeeded() {
        inProgress = true
        inProgressSubscription = Just(Void.self)
            .delay(for: .seconds(0.3), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                if self.inProgress == true {
                    SVProgressHUD.show()
                }
                self.inProgress = false
            }
    }

    private func hideProgressHUDIfNeeded() {
        inProgress = false
        SVProgressHUD.dismiss()
    }
    
    func showWarningAlertIfNeeded(completion: @escaping () -> Void) {
        showProgressHUDIfNeeded()
        let backupNodes = sharedBackupNodes()
        hideProgressHUDIfNeeded()
        
        if backupNodes == nodes {
            presentWarningAlert(title: Strings.Localizable.permissions,
                                message: Strings.Localizable.Mybackups.Share.Folder.Warning.message(nodes.count)) {
                completion()
            }
        } else if backupNodes.isNotEmpty {
            presentWarningAlert(title: Strings.Localizable.permissions,
                                message: Strings.Localizable.Dialog.Share.Backup.Non.Backup.Folders.Warning.message) {
                completion()
            }
        } else {
            completion()
        }
    }
}
