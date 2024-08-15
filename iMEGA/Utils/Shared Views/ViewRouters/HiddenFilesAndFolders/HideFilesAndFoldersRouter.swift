import MEGADomain
import MEGASDKRepo
import SwiftUI

protocol HideFilesAndFoldersRouting {
    func hideNodes(_ nodes: [NodeEntity])
    func showSeeUpgradePlansOnboarding()
    func showFirstTimeOnboarding(nodes: [NodeEntity])
    func showItemsHiddenSuccessfully(count: Int)
    func dismissOnboarding(animated: Bool, completion: (() -> Void)?)
}

final class HideFilesAndFoldersRouter: HideFilesAndFoldersRouting {
    private weak var presenter: UIViewController?
    private weak var onboardingViewController: UIViewController?
    
    init(presenter: UIViewController?) {
        self.presenter = presenter
    }
    
    func hideNodes(_ nodes: [NodeEntity]) {
        Task { @MainActor in
            let viewModel = makeViewModel(nodes: nodes)
            await viewModel.hide()
        }
    }
    
    @MainActor
    func showSeeUpgradePlansOnboarding() {
        showHiddenFilesAndFoldersOnboarding(
            primaryButtonViewModel: HiddenFilesSeeUpgradePlansOnboardingButtonViewModel(
                hideFilesAndFoldersRouter: self,
                upgradeAccountRouter: UpgradeAccountRouter())
        )
    }
    
    @MainActor
    func showFirstTimeOnboarding(nodes: [NodeEntity]) {
        showHiddenFilesAndFoldersOnboarding(
            primaryButtonViewModel: FirstTimeOnboardingPrimaryButtonViewModel(
                nodes: nodes,
                contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(
                    repo: UserAttributeRepository.newRepo),
                hideFilesAndFoldersRouter: self)
        )
    }
    
    func showItemsHiddenSuccessfully(count: Int) {
        // This will be done in future ticket
    }
    
    @MainActor
    func dismissOnboarding(animated: Bool, completion: (() -> Void)?) {
        onboardingViewController?.dismiss(animated: true, completion: completion)
    }
    
    @MainActor
    private func showHiddenFilesAndFoldersOnboarding(
        primaryButtonViewModel: some HiddenFilesOnboardingPrimaryButtonViewModelProtocol
    ) {
        let onboardingViewController = UIHostingController(rootView: HiddenFilesFoldersOnboardingView(
            primaryButton: HiddenFilesOnboardingButtonView(
                viewModel: primaryButtonViewModel)
        ))
        self.onboardingViewController = onboardingViewController
        presenter?.present(onboardingViewController,
                           animated: true)
    }
    
    @MainActor
    private func makeViewModel(nodes: [NodeEntity]) -> HideFilesAndFoldersViewModel {
        HideFilesAndFoldersViewModel(
            nodes: nodes,
            router: self,
            accountUseCase: AccountUseCase(
                repository: AccountRepository.newRepo),
            nodeActionUseCase: NodeActionUseCase(
                repo: NodeActionRepository.newRepo),
            contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(
                repo: UserAttributeRepository.newRepo))
    }
}
