
final class FileVersioningViewRouter: NSObject, FileVersioningViewRouting {
    private weak var baseViewController: UIViewController?
    private weak var navigationController: UINavigationController?
    
    @objc init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func build() -> UIViewController {
        let sdk = MEGASdkManager.sharedMEGASdk()
        let repo = FileVersionsRepository(sdk: sdk)
        let useCase = FileVersionsUseCase(repo: repo)
        let accountRepo = AccountRepository(sdk: sdk)
        let accounUseCase = AccountUseCase(repository: accountRepo)
        let vm = FileVersioningViewModel(router: self, fileVersionsUseCase: useCase, accountUseCase: accounUseCase)
        let vc = UIStoryboard(name: "FileVersioning", bundle: nil).instantiateViewController(withIdentifier: "FileVersioningTableViewControllerID") as! FileVersioningTableViewController
        baseViewController = vc
        vc.viewModel = vm
        return vc
    }
    
    @objc func start() {
        navigationController?.pushViewController(build(), animated: true)
    }
    
    func showDisableAlert(completion: @escaping (Bool) -> Void) {
        let title = NSLocalizedString("When file versioning is disabled, the current version will be replaced with the new version once a file is updated (and your changes to the file will no longer be recorded). Are you sure you want to disable file versioning?", comment: "A confirmation message when the user chooses to disable file versioning.")
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("no", comment: ""), style: .cancel, handler: {_ in
            completion(false)
        }))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("yes", comment: ""), style: .default, handler: {_ in
            completion(true)
        }))
        baseViewController?.present(alertController, animated: true, completion: nil)
    }
    
    func showDeletePreviousVersionsAlert(completion: @escaping (Bool) -> Void) {
        let title = NSLocalizedString("Delete all older versions of my files", comment: "The title of the section about deleting file versions in the settings.")
        let message = NSLocalizedString("You are about to delete the version histories of all files. Any file version shared to you from a contact will need to be deleted by them.[Br][Br]Please note that the current files will not be deleted.", comment: "Text of the dialog to delete all the file versions of the account").replacingOccurrences(of: "\n\n", with: "\n")
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("no", comment: ""), style: .cancel, handler:nil))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("yes", comment: ""), style: .default, handler: {_ in
            completion(true)
        }))
        baseViewController?.present(alertController, animated: true, completion: nil)
    }
}
