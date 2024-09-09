import MEGAAnalyticsiOS
import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASDKRepo
import MEGASwiftUI
import SwiftUI

protocol HideFilesAndFoldersRouting {
    func hideNodes(_ nodes: [NodeEntity])
    func showSeeUpgradePlansOnboarding()
    func showFirstTimeOnboarding(nodes: [NodeEntity])
    func showOnboardingInfo()
    func showItemsHiddenSuccessfully(count: Int)
    func dismissOnboarding(animated: Bool, completion: (() -> Void)?)
}

final class HideFilesAndFoldersRouter: HideFilesAndFoldersRouting {
    private weak var presenter: UIViewController?
    private weak var onboardingViewController: UIViewController?
    private let snackBarPresentation: SnackBarPresentation
    
    enum SnackBarPresentation {
        case router(SnackBarRouter)
        case observablePresenting(any SnackBarObservablePresenting)
        case none
    }
    
    init(presenter: UIViewController?, snackBarPresentation: SnackBarPresentation = .none) {
        self.presenter = presenter
        self.snackBarPresentation = snackBarPresentation
    }
    
    func hideNodes(_ nodes: [NodeEntity]) {
        Task { @MainActor in
            let viewModel = makeViewModel(nodes: nodes)
            await viewModel.hide()
        }
    }
    
    @MainActor
    func showSeeUpgradePlansOnboarding() {
        let viewModel = HiddenFilesFoldersOnboardingViewModel(
            showPrimaryButtonOnly: false,
            tracker: DIContainer.tracker,
            screenEvent: HideNodeUpgradeScreenEvent(),
            dismissEvent: HiddenNodeUpgradeCloseButtonPressedEvent())
        
        showHiddenFilesAndFoldersOnboarding(
            primaryButtonViewModel: HiddenFilesSeeUpgradePlansOnboardingButtonViewModel(
                hideFilesAndFoldersRouter: self,
                upgradeAccountRouter: UpgradeAccountRouter(),
                tracker: DIContainer.tracker),
            viewModel: viewModel
        )
    }
    
    @MainActor
    func showFirstTimeOnboarding(nodes: [NodeEntity]) {
        let viewModel = HiddenFilesFoldersOnboardingViewModel(
            showPrimaryButtonOnly: false,
            tracker: DIContainer.tracker,
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
    
    @MainActor
    func showOnboardingInfo() {
        let viewModel = HiddenFilesFoldersOnboardingViewModel(
            showPrimaryButtonOnly: true,
            showNavigationBar: false)
        
        showHiddenFilesAndFoldersOnboarding(
            primaryButtonViewModel: HiddenFilesCloseOnboardingPrimaryButtonViewModel(
                hideFilesAndFoldersRouter: self),
            viewModel: viewModel
        )
    }
    
    @MainActor
    func showItemsHiddenSuccessfully(count: Int) {
        let snackBar = SnackBar(message: Strings.Localizable.Nodes.Action.hideItems(count))
        switch snackBarPresentation {
        case .observablePresenting(let presenter):
            presenter.show(snack: snackBar)
        case .router(let router):
            router.present(snackBar: snackBar)
        case .none:
            break
        }
    }
    
    @MainActor
    func dismissOnboarding(animated: Bool, completion: (() -> Void)?) {
        onboardingViewController?.dismiss(animated: true, completion: completion)
    }
    
    @MainActor
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
