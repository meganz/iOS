import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain
import MEGASwift
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

    private weak var viewController: MediaTabViewController?
    private let nodeAccessoryActionDelegate: DefaultNodeAccessoryActionDelegate

    init(viewController: MediaTabViewController) {
        self.viewController = viewController
        self.nodeAccessoryActionDelegate = DefaultNodeAccessoryActionDelegate()
    }

    func handleToolbarAction(_ action: MediaBottomToolbarAction, with nodes: [NodeEntity]) {
        guard let viewController else { return }

        // Convert once, here, for the whole action. Both call sites below used to convert
        // independently and drop unresolvable handles silently, so the sheet the user was shown
        // could describe a different set from the one that executed.
        let megaNodes = nodes.compactMap { $0.toMEGANode(in: .sharedSdk) }
        guard megaNodes.isNotEmpty else { return }

        switch action {
        case .more:
            presentMoreActions(for: megaNodes, from: viewController)
        case .download:
            executeNodeAction(.download, for: megaNodes, from: viewController)
        case .manageLink:
            executeNodeAction(.manageLink, for: megaNodes, from: viewController)
        case .saveToPhotos:
            executeNodeAction(.saveToPhotos, for: megaNodes, from: viewController)
        case .sendToChat:
            executeNodeAction(.sendToChat, for: megaNodes, from: viewController)
        case .addToAlbum:
            executeNodeAction(.addToAlbum, for: megaNodes, from: viewController)
        case .moveToRubbishBin:
            executeNodeAction(.moveToRubbishBin, for: megaNodes, from: viewController)
        default:
            break
        }
    }

    // MARK: - Private Methods

    private func presentMoreActions(for nodes: [MEGANode], from viewController: MediaTabViewController) {
        let nodeActionViewController = createNodeActionViewController(
            displayMode: viewController.nodeActionDisplayMode,
            with: nodes,
            from: viewController
        )
        viewController.present(nodeActionViewController, animated: true, completion: nil)
    }

    private func executeNodeAction(
        _ actionType: MegaNodeActionType,
        for nodes: [MEGANode],
        from viewController: MediaTabViewController
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
        with nodes: [MEGANode],
        from viewController: MediaTabViewController
    ) -> NodeActionViewController {
        let nodeActionVC = NodeActionViewController(
            nodes: nodes,
            delegate: viewController,
            displayMode: displayMode,
            // Timeline reports .photosTimeline; the Videos tab falls back to .cloudDrive. Both present
            // file nodes and route .favourite through the generic delegate. The Albums tab has no .more
            // action, so it never reaches here.
            showsFavouriteAction: [.photosTimeline, .cloudDrive].contains(displayMode),
            showsLabelAction: [.photosTimeline, .cloudDrive].contains(displayMode),
            sender: viewController.toolbar
        )
        nodeActionVC.accessoryActionDelegate = nodeAccessoryActionDelegate
        return nodeActionVC
    }

    private func handleNodesAction(
        _ nodeAction: NodeActionViewController,
        action: MegaNodeActionType,
        nodes: [MEGANode],
        from viewController: MediaTabViewController
    ) {
        viewController.nodeAction(nodeAction, didSelect: action, forNodes: nodes, from: viewController.toolbar)
    }
}
