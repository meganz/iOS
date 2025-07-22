import MEGAAppSDKRepo
import MEGADomain
import MEGARepo

final class DownloadLinkRouter: DownloadLinkRouterProtocol {
    private weak var baseViewController: UIViewController?
    private weak var presenter: UIViewController?
    private(set) weak var viewModel: DownloadLinkViewModel?
    
    private let link: URL?
    private let isFolderLink: Bool
    private let nodes: [NodeEntity]?

    init(link: URL,
         isFolderLink: Bool,
         presenter: UIViewController) {
        self.isFolderLink = isFolderLink
        self.link = link
        self.nodes = nil
        self.presenter = presenter
    }
    
    init(nodes: [NodeEntity],
         isFolderLink: Bool,
         presenter: UIViewController) {
        self.isFolderLink = isFolderLink
        self.link = nil
        self.nodes = nodes
        self.presenter = presenter
    }
    
    func start() {
        let credentialUseCase = CredentialUseCase(repo: CredentialRepository.newRepo)
        let viewModel: DownloadLinkViewModel
        if isFolderLink {
            guard let nodes = nodes else {
                return
            }
            viewModel = DownloadLinkViewModel(router: self, credentialUseCase: credentialUseCase, nodes: nodes, isFolderLink: isFolderLink)
        } else {
            guard let link = link else {
                return
            }
            viewModel = DownloadLinkViewModel(router: self, credentialUseCase: credentialUseCase, link: link, isFolderLink: isFolderLink)
        }
        viewModel.checkIfLinkCanBeDownloaded()
    }
    
    func downloadFileLink() {
        guard let presenter = presenter else { return }

        let transferViewEntity = CancellableTransfer(fileLinkURL: link, name: nil, appData: nil, priority: false, isFile: true, type: .downloadFileLink)
        CancellableTransferRouter(presenter: presenter, transfers: [transferViewEntity], transferType: .downloadFileLink).start()
    }
    
    func downloadFolderLinkNodes() {
        guard let presenter = presenter, let nodes = nodes else { return }
        let transfers = nodes.map { CancellableTransfer(handle: $0.handle, name: nil, appData: nil, priority: false, isFile: $0.isFile, type: .download) }
        CancellableTransferRouter(presenter: presenter, transfers: transfers, transferType: .download, isFolderLink: true).start()
    }

    func showOnboarding() {
        guard let presenter = presenter else { return }
        let onboardingVC = OnboardingViewController.instantiateOnboarding(with: .default)
        if let navigation = presenter.navigationController {
            navigation.pushViewController(onboardingVC, animated: true)
        } else {
            let navigation = MEGANavigationController(rootViewController: onboardingVC)
            navigation.addRightCancelButton()
            presenter.present(navigation, animated: true)
        }
    }
}
