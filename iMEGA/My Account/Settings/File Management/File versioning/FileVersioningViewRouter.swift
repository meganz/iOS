import MEGADomain
import MEGAL10n
import MEGASDKRepo

final class FileVersioningViewRouter: NSObject, FileVersioningViewRouting {
    private weak var baseViewController: UIViewController?
    private weak var navigationController: UINavigationController?
    
    @objc init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func build() -> UIViewController {
        let sdk = MEGASdk.shared
        let repo = FileVersionsRepository(sdk: sdk)
        let useCase = FileVersionsUseCase(repo: repo)
        let accountRepo = AccountRepository.newRepo
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
        let title = Strings.Localizable.WhenFileVersioningIsDisabledTheCurrentVersionWillBeReplacedWithTheNewVersionOnceAFileIsUpdatedAndYourChangesToTheFileWillNoLongerBeRecorded.areYouSureYouWantToDisableFileVersioning
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: Strings.Localizable.no, style: .cancel, handler: {_ in
            completion(false)
        }))
        alertController.addAction(UIAlertAction(title: Strings.Localizable.yes, style: .default, handler: {_ in
            completion(true)
        }))
        baseViewController?.present(alertController, animated: true, completion: nil)
    }
    
    func showDeletePreviousVersionsAlert(completion: @escaping (Bool) -> Void) {
        let title = Strings.Localizable.deleteAllOlderVersionsOfMyFiles
        let message = Strings.Localizable.YouAreAboutToDeleteTheVersionHistoriesOfAllFiles.AnyFileVersionSharedToYouFromAContactWillNeedToBeDeletedByThem.brBrPleaseNoteThatTheCurrentFilesWillNotBeDeleted.replacingOccurrences(of: "\n\n", with: "\n")
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: Strings.Localizable.no, style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: Strings.Localizable.yes, style: .default, handler: {_ in
            completion(true)
        }))
        baseViewController?.present(alertController, animated: true, completion: nil)
    }
}
