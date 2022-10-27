import Combine
import MEGADomain

final class BackupNodesValidator {
    private let myBackupsUseCase: MyBackupsUseCaseProtocol
    private let nodes: [NodeEntity]
    private let presenter: UIViewController
    private var inProgress = false
    private var inProgressSubscription: AnyCancellable?
    
    init(presenter: UIViewController, myBackupsUseCase: MyBackupsUseCaseProtocol = MyBackupsUseCase(myBackupsRepository: MyBackupsRepository.newRepo, nodeRepository: NodeRepository.newRepo), nodes: [NodeEntity]) {
        self.presenter = presenter
        self.myBackupsUseCase = myBackupsUseCase
        self.nodes = nodes
    }
    
    @MainActor
    private func presentWarningAlert(title: String, message: String, completion: @MainActor @escaping () -> Void) {
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
    
    private func sharedBackupNodes() async -> [NodeEntity] {
        await withTaskGroup(of: NodeEntity?.self) { group -> [NodeEntity] in
            nodes.forEach { node in
                group.addTask {
                    await self.myBackupsUseCase.isBackupNode(node) ? node : nil
                }
            }
            
            return await group.reduce(into: [NodeEntity](), {
                if let node = $1 { $0.append(node) }
            })
        }
    }

    private func showProgressHUDIfNeeded() {
        inProgress = true
        inProgressSubscription = Just(Void.self)
            .delay(for: .seconds(0.3), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
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
    
    func showWarningAlertIfNeeded(completion: @MainActor @escaping () -> Void) {
        Task {
            showProgressHUDIfNeeded()
            let backupNodes = await sharedBackupNodes()
            hideProgressHUDIfNeeded()
            
            if backupNodes == nodes {
                await presentWarningAlert(title: Strings.Localizable.permissions,
                                          message: Strings.Localizable.Mybackups.Share.Folder.Warning.message(nodes.count)) {
                    completion()
                }
            } else if backupNodes.isNotEmpty {
                await presentWarningAlert(title: Strings.Localizable.permissions,
                                          message: Strings.Localizable.Dialog.Share.Backup.Non.Backup.Folders.Warning.message) {
                    completion()
                }
            } else {
                await completion()
            }
        }
    }
}
