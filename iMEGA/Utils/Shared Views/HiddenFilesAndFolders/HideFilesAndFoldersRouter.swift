import MEGAAnalyticsiOS
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGAL10n
import MEGAPreference
import MEGASwiftUI
import SwiftUI

@MainActor
protocol HideFilesAndFoldersRouting {
    func hideNodes(_ nodes: [NodeEntity])
    func showSeeUpgradePlansOnboarding()
    func showFirstTimeOnboarding(nodes: [NodeEntity])
    func showOnboardingInfo()
    func showSnackBar(message: String)
    func dismissOnboarding(animated: Bool, completion: (() -> Void)?)
    func showUserInterfaceSettings()
}

@MainActor
final class HideFilesAndFoldersRouter: HideFilesAndFoldersRouting {
    private weak var presenter: UIViewController?
    private weak var onboardingViewController: UIViewController?
    
    init(presenter: UIViewController?) {
        self.presenter = presenter
    }
    
    func hideNodes(_ nodes: [NodeEntity]) {
        Task {
            let viewModel = makeViewModel(nodes: nodes)
            await viewModel.hide()
        }
    }
    
    func unhideNodes(_ nodes: [NodeEntity]) {
        Task {
            let viewModel = makeViewModel(nodes: nodes)
            await viewModel.unhide()
        }
    }
    
    func showSeeUpgradePlansOnboarding() {
        let viewModel = makeHiddenFilesFoldersOnboardingViewModel(
            showPrimaryButtonOnly: false,
            screenEvent: HideNodeUpgradeScreenEvent(),
            dismissEvent: HiddenNodeUpgradeCloseButtonPressedEvent())
        
        showHiddenFilesAndFoldersOnboarding(
            primaryButtonViewModel: HiddenFilesSeeUpgradePlansOnboardingButtonViewModel(
                hideFilesAndFoldersRouter: self,
                upgradeSubscriptionRouter: UpgradeSubscriptionRouter(
                    presenter: presenter),
                tracker: DIContainer.tracker),
            viewModel: viewModel
        )
    }
    
    func showFirstTimeOnboarding(nodes: [NodeEntity]) {
        let viewModel = makeHiddenFilesFoldersOnboardingViewModel(
            showPrimaryButtonOnly: false,
            screenEvent: HideNodeOnboardingScreenEvent(),
            dismissEvent: HiddenNodeOnboardingCloseButtonPressedEvent())
        
        showHiddenFilesAndFoldersOnboarding(
            primaryButtonViewModel: FirstTimeOnboardingPrimaryButtonViewModel(
                nodes: nodes,
                contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(
                    repo: UserAttributeRepository.newRepo),
                hideFilesAndFoldersRouter: self,
                tracker: DIContainer.tracker),
            viewModel: viewModel
        )
    }
    
    func showOnboardingInfo() {
        let viewModel = makeHiddenFilesFoldersOnboardingViewModel(
            showPrimaryButtonOnly: true,
            showNavigationBar: false)
        
        showHiddenFilesAndFoldersOnboarding(
            primaryButtonViewModel: HiddenFilesCloseOnboardingPrimaryButtonViewModel(
                hideFilesAndFoldersRouter: self),
            viewModel: viewModel
        )
    }
    
    func showSnackBar(message: String) {
        let snackBar = SnackBar(message: message)
        UIApplication.mnz_visibleViewController()
            .showSnackBar(snackBar: snackBar)
    }
    
    func dismissOnboarding(animated: Bool, completion: (() -> Void)?) {
        onboardingViewController?.dismiss(animated: true, completion: completion)
    }
    
    func showUserInterfaceSettings() {
        let viewController = UIStoryboard(name: "Appearance", bundle: nil)
            .instantiateViewController(identifier: "AppearanceTableViewControllerID") { coder in
                let viewModel = AppearanceViewModel(
                    preferenceUseCase: PreferenceUseCase(
                        repository: PreferenceRepository.newRepo),
                    sensitiveNodeUseCase: SensitiveNodeUseCase(
                        nodeRepository: NodeRepository.newRepo,
                        accountUseCase: AccountUseCase(repository: AccountRepository.newRepo)),
                    contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(
                        repo: UserAttributeRepository.newRepo))
                return AppearanceTableViewController(coder: coder, viewModel: viewModel)
            }
        
        let navigationController = MEGANavigationController(rootViewController: viewController)
        navigationController.addLeftDismissButton(withText: Strings.Localizable.cancel)
        navigationController.modalPresentationStyle = .fullScreen
        onboardingViewController?.present(navigationController, animated: true)
    }
    
    private func showHiddenFilesAndFoldersOnboarding(
        primaryButtonViewModel: some HiddenFilesOnboardingPrimaryButtonViewModelProtocol,
        viewModel: HiddenFilesFoldersOnboardingViewModel
    ) {
        let onboardingViewController = UIHostingController(rootView: HiddenFilesFoldersOnboardingView(
            primaryButton: HiddenFilesOnboardingButtonView(
                viewModel: primaryButtonViewModel),
            viewModel: viewModel
        ))
        self.onboardingViewController = onboardingViewController
        presenter?.present(onboardingViewController,
                           animated: true)
    }
    
    private func makeViewModel(nodes: [NodeEntity]) -> HideFilesAndFoldersViewModel {
        HideFilesAndFoldersViewModel(
            nodes: nodes,
            router: self,
            sensitiveNodeUseCase: SensitiveNodeUseCase(
                nodeRepository: NodeRepository.newRepo,
                accountUseCase: AccountUseCase(repository: AccountRepository.newRepo)),
            nodeActionUseCase: NodeActionUseCase(
                repo: NodeActionRepository.newRepo),
            contentConsumptionUserAttributeUseCase: ContentConsumptionUserAttributeUseCase(
                repo: UserAttributeRepository.newRepo))
    }
    
    private func makeHiddenFilesFoldersOnboardingViewModel(
        showPrimaryButtonOnly: Bool,
        screenEvent: (any ScreenViewEventIdentifier)? = nil,
        dismissEvent: (any ButtonPressedEventIdentifier)? = nil,
        showNavigationBar: Bool = true,
    ) -> HiddenFilesFoldersOnboardingViewModel {
        HiddenFilesFoldersOnboardingViewModel(
            showPrimaryButtonOnly: showPrimaryButtonOnly,
            sensitiveNodeUseCase: SensitiveNodeUseCase(
                nodeRepository: NodeRepository.newRepo,
                accountUseCase: AccountUseCase(
                    repository: AccountRepository.newRepo)),
            hideFilesAndFoldersRouter: self,
            showNavigationBar: showNavigationBar,
            screenEvent: screenEvent,
            dismissEvent: dismissEvent
        )
    }
}
