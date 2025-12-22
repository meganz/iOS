import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import UIKit

// MARK: - Coordinator Protocol

@MainActor
protocol MediaTabToolbarCoordinatorProtocol: AnyObject {
    /// Handle a toolbar action with the given nodes
    /// - Parameters:
    ///   - action: The toolbar action to perform
    ///   - nodes: The selected nodes to perform the action on
    func handleToolbarAction(_ action: MediaBottomToolbarAction, with nodes: [NodeEntity])
}

// MARK: - Coordinator Implementation

@MainActor
final class MediaTabToolbarCoordinator: MediaTabToolbarCoordinatorProtocol {

    private weak var viewController: MediaTabHostingController?
    private let nodeAccessoryActionDelegate: DefaultNodeAccessoryActionDelegate

    init(viewController: MediaTabHostingController) {
        self.viewController = viewController
        self.nodeAccessoryActionDelegate = DefaultNodeAccessoryActionDelegate()
    }

    func handleToolbarAction(_ action: MediaBottomToolbarAction, with nodes: [NodeEntity]) {
        guard let viewController, !nodes.isEmpty else { return }

        switch action {
        case .more:
            presentMoreActions(for: nodes, from: viewController)
        case .download:
            executeNodeAction(.download, for: nodes, from: viewController)
        case .manageLink:
            executeNodeAction(.manageLink, for: nodes, from: viewController)
        case .saveToPhotos:
            executeNodeAction(.saveToPhotos, for: nodes, from: viewController)
        case .sendToChat:
            executeNodeAction(.sendToChat, for: nodes, from: viewController)
        case .addToAlbum:
            executeNodeAction(.addToAlbum, for: nodes, from: viewController)
        case .moveToRubbishBin:
            executeNodeAction(.moveToRubbishBin, for: nodes, from: viewController)
        default:
            break
        }
    }

    // MARK: - Private Methods

    private func presentMoreActions(for nodes: [NodeEntity], from viewController: MediaTabHostingController) {
        let nodeActionViewController = createNodeActionViewController(
            displayMode: viewController.nodeActionDisplayMode,
            with: nodes,
            from: viewController
        )
        viewController.present(nodeActionViewController, animated: true, completion: nil)
    }

    private func executeNodeAction(
        _ actionType: MegaNodeActionType,
        for nodes: [NodeEntity],
        from viewController: MediaTabHostingController
    ) {
        let nodeActionViewController = createNodeActionViewController(
            displayMode: viewController.nodeActionDisplayMode,
            with: nodes,
            from: viewController
        )

        handleNodesAction(
            nodeActionViewController,
            action: actionType,
            nodes: nodes,
            from: viewController
        )
    }

    private func createNodeActionViewController(
        displayMode: DisplayMode,
        with nodes: [NodeEntity],
        from viewController: MediaTabHostingController
    ) -> NodeActionViewController {
        let nodeActionVC = NodeActionViewController(
            nodes: nodes.compactMap { $0.toMEGANode(in: .sharedSdk) },
            delegate: viewController,
            displayMode: displayMode,
            sender: viewController.toolbar
        )
        nodeActionVC.accessoryActionDelegate = nodeAccessoryActionDelegate
        return nodeActionVC
    }

    private func handleNodesAction(
        _ nodeAction: NodeActionViewController,
        action: MegaNodeActionType,
        nodes: [NodeEntity],
        from viewController: MediaTabHostingController
    ) {
        viewController.nodeAction(nodeAction, didSelect: action, forNodes: nodes.compactMap { $0.toMEGANode(in: .sharedSdk) }, from: viewController.toolbar)
    }
}
