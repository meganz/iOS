import Foundation
import MEGADomain
import MEGAPresentation
import MEGASDKRepo
import MessageKit
import SwiftUI

struct NodeShareRouter {

    private weak var viewController: UIViewController?

    init(viewController: UIViewController? = nil) {
        self.viewController = viewController
    }

    // MARK: -

    func exportFile(from node: MEGANode, sender: Any?) {
        guard let presenter = viewController else {
            return
        }
        ExportFileRouter(presenter: presenter, sender: sender).export(node: node.toNodeEntity())
    }

    func showSharingFolder(for node: MEGANode) {
        showSharingFolders(for: [node])
    }
    
    func showSharingFolders(for nodes: [MEGANode]) {
        guard let viewController = viewController else { return }
        BackupNodesValidator(presenter: viewController, nodes: nodes.toNodeEntities()).showWarningAlertIfNeeded {
            let viewControllerToPresent = if DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .hiddenNodes) {
                copyrightWrappedShareFoldersViewController(nodes: nodes)
            } else {
                makeContactsShareFoldersViewController(nodes: nodes)
            }
            viewController.present(viewControllerToPresent, animated: true, completion: nil)
        }
    }
    
    func showManageSharing(for nodeEntity: NodeEntity) {
        if let megaNode = MEGASdk.shared.node(forHandle: nodeEntity.handle) {
            showManageSharing(for: megaNode)
        }
    }
    
    private static func makeContactViewController(for node: MEGANode) -> UIViewController? {
        guard
            let contactViewController = UIStoryboard(name: "Contacts", bundle: nil)
            .instantiateViewController(withIdentifier: "ContactsViewControllerID") as? ContactsViewController
        else { return nil}
        contactViewController.node = node
        contactViewController.contactsMode = .folderSharedWith
        return contactViewController
    }

    func showManageSharing(for node: MEGANode) {
        guard let viewController = viewController else { return }
        BackupNodesValidator(presenter: viewController, nodes: [node.toNodeEntity()]).showWarningAlertIfNeeded {
            guard let contactsVC = Self.makeContactViewController(for: node) else { return }
            viewController.present(contactsVC, animated: true, completion: nil)
        }
    }
    
    func pushManageSharing(for node: NodeEntity, on navigationController: UINavigationController?) {
        guard 
            let navigationController,
            let megaNode = MEGASdk.shared.node(forHandle: node.handle),
            let contactsVC = Self.makeContactViewController(for: megaNode)
        else { return }
        
        navigationController.pushViewController(contactsVC, animated: true)
    }
    
    private func makeContactsShareFoldersViewController(nodes: [MEGANode]) -> MEGANavigationController {
        guard let contactsVC = UIStoryboard(name: "Contacts", bundle: nil).instantiateViewController(
            withIdentifier: "ContactsViewControllerID") as? ContactsViewController else {
            fatalError("Could not instantiate ContactsViewController")
        }
        contactsVC.contactsMode = .shareFoldersWith
        contactsVC.nodesArray = nodes
        return MEGANavigationController(rootViewController: contactsVC)
    }
    
    private func copyrightWrappedShareFoldersViewController(nodes: [MEGANode]) -> UIViewController {
        let copyrightUseCase = CopyrightUseCase(
            shareUseCase: ShareUseCase(
                shareRepository: ShareRepository.newRepo,
                filesSearchRepository: FilesSearchRepository.newRepo,
                nodeRepository: NodeRepository.newRepo),
            userAlbumRepository: UserAlbumRepository.newRepo)
        let viewModel = EnforceCopyrightWarningViewModel(preferenceUseCase: PreferenceUseCase.default,
                                                         copyrightUseCase: copyrightUseCase)
        
        let view = EnforceCopyrightWarningView(viewModel: viewModel) {
            ContactsView(nodes: nodes,
                         mode: .shareFoldersWith)
            .ignoresSafeArea(edges: .bottom)
        }
        return UIHostingController(rootView: view)
    }
}
