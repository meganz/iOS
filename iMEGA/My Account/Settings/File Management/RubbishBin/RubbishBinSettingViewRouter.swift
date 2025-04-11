import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAL10n
import SwiftUI

final class RubbishBinSettingViewRouter: Routing {
    private weak var baseViewController: UIViewController?
    private weak var navigationController: UINavigationController?
    
    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }
    
    func build() -> UIViewController {
        let accountUseCase = AccountUseCase(repository: AccountRepository.newRepo)
        let rubbishBinRepo = RubbishBinRepository.newRepo
        let rubbishBinSettingRepo = RubbishBinSettingsRepository(isPaidAccount: accountUseCase.isPaidAccount, serverSideRubbishBinAutopurgeEnabled: rubbishBinRepo.serverSideRubbishBinAutopurgeEnabled())
        let rubbishBinSettingsUseCase = RubbishBinSettingsUseCase(rubbishBinSettingsRepository: rubbishBinSettingRepo)
        let hostingVC = UIHostingController(rootView: RubbishBinSettingView(viewModel: RubbishBinSettingViewModel(accountUseCase: accountUseCase, rubbishBinSettingsUseCase: rubbishBinSettingsUseCase)))
        hostingVC.title = Strings.Localizable.Settings.FileManagement.RubbishBin.Navigation.title
        
        baseViewController = hostingVC
        return hostingVC
    }
    
    func start() {
        navigationController?.pushViewController(build(), animated: true)
    }
}
