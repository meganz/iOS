import MEGAAppSDKRepo
import MEGAAuthentication
import MEGADomain
import MEGARepo

/// Router that will either show the import destination if signed in, or display onboarding and handle the action after login.
/// - Important: MEGANode is used because converting a NodeEntity back to MEGANode won't work in some scenarios, such as when the node is retrieved via a `publicNode`.
final class ImportLinkRouter: ImportLinkRouting {
    private let isFolderLink: Bool
    private let nodes: [MEGANode]
    private var importCompletion: (() -> Void)?
    private weak var presenter: UIViewController?
    
    init(
        isFolderLink: Bool,
        nodes: [MEGANode],
        presenter: UIViewController,
        importCompletion: (() -> Void)? = nil
    ) {
        self.isFolderLink = isFolderLink
        self.nodes = nodes
        self.presenter = presenter
        self.importCompletion = importCompletion
    }
    
    func start() {
        let viewModel = ImportLinkViewModel(
            router: self,
            credentialUseCase: CredentialUseCase(repo: CredentialRepository.newRepo),
            isFolderLink: isFolderLink,
            nodes: nodes)
        viewModel.importNodes()
    }
    
    func showNodeBrowser() {
        guard let navigationController = UIStoryboard(name: "Cloud", bundle: nil)
            .instantiateViewController(withIdentifier: "BrowserNavigationControllerID") as? MEGANavigationController,
              let browserVC = navigationController.viewControllers.first as? BrowserViewController else {
            return
        }
        browserVC.selectedNodesArray = nodes
        browserVC.browserAction = isFolderLink ? .importFromFolderLink : .import
        browserVC.onCopyNodesCompletion = importCompletion

        if isFolderLink {
            presenter?.present(navigationController, animated: true)
        } else {
            guard let presentingVC = presenter?.presentingViewController else {
                presenter?.present(navigationController, animated: true)
                return
            }
            presenter?.dismiss(animated: true) { [weak presentingVC] in
                presentingVC?.present(navigationController, animated: true)
            }
        }
    }
    
    func showOnboarding() {
        guard let presenter = presenter else { return }
        let onboardingVC = OnboardingUSPViewController()
        if let navigation = presenter.navigationController {
            navigation.pushViewController(onboardingVC, animated: true)
        } else {
            let navigation = MEGANavigationController(rootViewController: onboardingVC)
            navigation.addRightCancelButton()
            presenter.present(navigation, animated: true)
        }
    }
}
