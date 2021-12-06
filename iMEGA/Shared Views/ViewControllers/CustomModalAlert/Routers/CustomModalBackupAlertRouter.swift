import Foundation
import UIKit

enum BackupAction {
    case move
    case moveToRubbishBin
    case addFolder
    case confirmMove
    case confirmMoveToRubbishBin
    case confirmAddFolder
}

struct BackupAlertConfiguration {
    let node: MEGANode
    let title: String
    let description: String
    let actionTitle: String
    var confirmPlaceholder: String = ""
    var iconName: String = "warningModals"
    var dismissTitle: String = NSLocalizedString("cancel", comment: "")
}

final class CustomModalBackupAlertRouter: Routing {
    private let backupAlertData: BackupAlertConfiguration
    private var presenterVC: UIViewController
    private var actionCompletion: (() -> Void)
    private var dismissCompletion: (() -> Void)
    
    init(backupAlertData: BackupAlertConfiguration,
         presenter: UIViewController,
         actionCompletion: @escaping () -> Void = {},
         dismissCompletion: @escaping  () -> Void = {}){
        self.backupAlertData = backupAlertData
        self.presenterVC = presenter
        self.actionCompletion = actionCompletion
        self.dismissCompletion = dismissCompletion
    }
    
    func build() -> UIViewController {
        let customModalAlertVC = CustomModalAlertViewController()
        customModalAlertVC.image = UIImage(named: backupAlertData.iconName)
        customModalAlertVC.viewTitle = backupAlertData.title
        customModalAlertVC.detail = backupAlertData.description
        if backupAlertData.confirmPlaceholder != "" {
            customModalAlertVC.confirmationPlaceholder = backupAlertData.confirmPlaceholder
        }
        customModalAlertVC.firstButtonTitle = backupAlertData.actionTitle
        customModalAlertVC.dismissButtonTitle = backupAlertData.dismissTitle
        customModalAlertVC.firstCompletion = {
            customModalAlertVC.dismiss(animated: true) {  [weak self] in
                self?.actionCompletion()
            }
        }
        customModalAlertVC.dismissCompletion = {
            customModalAlertVC.dismiss(animated: true) {  [weak self] in
                self?.dismissCompletion()
            }
        }
        
        return customModalAlertVC
    }
    
    func start() {
        presenterVC.present(build(), animated: true, completion: nil)
    }
}
