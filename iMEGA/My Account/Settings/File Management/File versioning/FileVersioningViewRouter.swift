import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASDKRepo
import Settings
import SwiftUI

final class FileVersioningViewRouter: NSObject, FileVersioningViewRouting {
    private weak var baseViewController: UIViewController?
    private weak var navigationController: UINavigationController?
    
    @objc init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func build() -> UIViewController {
        if DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .newSetting) {
            let viewModel = FileVersioningViewModel(
                fileVersionsUseCase: FileVersionsUseCase(repo: FileVersionsRepository.newRepo),
                accountUseCase: AccountUseCase(repository: AccountRepository.newRepo)
            )
            let hostingVC = UIHostingController(
                rootView: FileVersioningView(viewModel: viewModel)
            )
            baseViewController = hostingVC
            return hostingVC
        } else {
            let vc = UIStoryboard(name: "FileVersioning", bundle: nil).instantiateViewController(withIdentifier: "FileVersioningTableViewControllerID") as! FileVersioningTableViewController
            vc.viewModel = LegacyFileVersioningViewModel(
                router: self,
                fileVersionsUseCase: FileVersionsUseCase(repo: FileVersionsRepository.newRepo),
                accountUseCase: AccountUseCase(repository: AccountRepository.newRepo)
            )
            baseViewController = vc
            return vc
        }
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
