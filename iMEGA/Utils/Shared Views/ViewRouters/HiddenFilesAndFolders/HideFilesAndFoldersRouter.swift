import MEGADomain
import MEGASDKRepo
import SwiftUI

struct HideFilesAndFoldersRouter: HideFilesAndFoldersRouting {
    private weak var presenter: UIViewController?
    
    init(presenter: UIViewController?) {
        self.presenter = presenter
    }
    
    func hideNodes(_ nodes: [NodeEntity]) {
        Task { @MainActor in
            let viewModel = makeViewModel(nodes: nodes)
            await viewModel.hideNodes()
        }
    }
    
    func showHiddenFilesAndFoldersOnboarding() {
        presenter?.present(makeOnboardingViewController(),
                           animated: true)
    }
    
    func showItemsHiddenSuccessfully(count: Int) {
        // This will be done in future ticket
    }
    
    private func makeOnboardingViewController() -> UIViewController {
        let onboardingView = HiddenFilesFoldersOnboardingView {
            presenter?.navigationController?.presentedViewController?.dismiss(animated: true, completion: {
                UpgradeAccountRouter().presentUpgradeTVC()
            })
        }
        return UIHostingController(rootView: onboardingView)
    }
    
    private func makeViewModel(nodes: [NodeEntity]) -> HideFilesAndFoldersViewModel {
        HideFilesAndFoldersViewModel(
            nodes: nodes,
            router: self,
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
            nodeActionUseCase: NodeActionUseCase(repo: NodeActionRepository.newRepo))
    }
}
