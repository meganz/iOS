import Foundation
import MEGADomain
import MEGAPresentation
import MEGASDKRepo

final class NodeInfoRouter: NSObject {

    private weak var navigationController: UINavigationController?
    private let contacstUseCase: any ContactsUseCaseProtocol

    init(navigationController: UINavigationController? = nil,
         contacstUseCase: some ContactsUseCaseProtocol
    ) {
        self.navigationController = navigationController
        self.contacstUseCase = contacstUseCase
    }

    // MARK: - Info
    
    func showInformation(for nodeEntity: NodeEntity) {
        if let megaNode = MEGASdk.shared.node(forHandle: nodeEntity.handle) {
            showInformation(for: megaNode)
        }
    }

    func showInformation(for node: MEGANode) {
        let viewModel = NodeInfoViewModel(
            withNode: node,
            shareUseCase: ShareUseCase(repo: ShareRepository.newRepo, filesSearchRepository: FilesSearchRepository.newRepo), 
            featureFlagProvider: DIContainer.featureFlagProvider,
            shouldDisplayContactVerificationInfo: MEGASdk.shared.isContactVerificationWarningEnabled
        )
        
        let nodeInfoVC = NodeInfoViewController.instantiate(withViewModel: viewModel, delegate: self)
        navigationController?.present(nodeInfoVC, animated: true, completion: nil)
    }
    
    // MARK: - Version
    
    func showVersions(for node: MEGANode) {
        guard let nodeVersionNavigation = navigationController else { return }
        node.mnz_showVersions(in: nodeVersionNavigation)
    }
}

extension NodeInfoRouter: NodeInfoViewControllerDelegate {

    func nodeInfoViewController(
        _ nodeInfoViewController: NodeInfoViewController,
        presentParentNode node: MEGANode
    ) {
        node.navigateToParentAndPresent()
    }
}
