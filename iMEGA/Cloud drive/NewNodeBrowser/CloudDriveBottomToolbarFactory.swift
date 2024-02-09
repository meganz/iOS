import ChatRepo
import Foundation
import MEGADomain
import MEGAL10n
import MEGAPermissions
import MEGASDKRepo

struct BottomToolbarConfig {
    let accessType: NodeAccessTypeEntity
    let displayMode: DisplayMode
    let isBackupNode: Bool
    let selectedNodes: [NodeEntity]
    let isIncomingShareChildView: Bool
    let onActionCompleted: (BottomToolbarAction) -> Void
}

// Responsibility of this factory is to take output from the actionFactory, which decided what are visible tool bar items,
// and turns them into actual UIBarButton items that can be placed in the UI. It also uses NodeActionsDelegateHandler
// to implement handling of the actions, both ones visible as buttons in the tool bar, as well as those
// found when tapping on "more" (ellipsis,···) button. This is done via injected instance of NodeActionsDelegateHandler
// When "more" is tapped, we present NodeActionViewController modally on the parent
struct CloudDriveBottomToolbarItemsFactory {
    
    let sdk: MEGASdk
    let nodeActionHandler: NodeActionsDelegateHandler
    let actionFactory: any ToolbarActionFactoryProtocol
    
    private func megaNodes(from nodeEntities: [NodeEntity]) -> [MEGANode] {
        nodeEntities.compactMap {
            sdk.node(forHandle: $0.handle)
        }
    }
    
    func buildToolbarItems(
        config: BottomToolbarConfig,
        parent: UIViewController,
        browseDelegate: BrowserViewControllerDelegateHandler
    ) -> [UIBarButtonItem] {
        
        let flexibleItem = UIBarButtonItem(systemItem: .flexibleSpace)
        
        var barButtons: [UIBarButtonItem] = []
        
        let actions = actionFactory.buildActions(
            accessType: config.accessType,
            isBackupNode: config.isBackupNode,
            displayMode: config.displayMode
        )
        
        for (index, action) in actions.enumerated() {
            
            let item = UIBarButtonItem(image: action.image)
            
            item.primaryAction = UIAction(
                image: action.image,
                handler: { _ in
                    actionHandler(
                        for: action,
                        displayMode: config.displayMode,
                        selectedNodes: config.selectedNodes,
                        isIncomingShareChildView: config.isIncomingShareChildView,
                        parent: parent,
                        sender: item,
                        onActionCompleted: config.onActionCompleted
                    )
                }
            )
            
            barButtons.append(item)
            
            if index < actions.count - 1 {
                barButtons.append(flexibleItem)
            }
        }
        
        return barButtons
    }
    
    private func actionHandler(
        for type: BottomToolbarAction,
        displayMode: DisplayMode,
        selectedNodes: [NodeEntity],
        isIncomingShareChildView: Bool,
        parent: UIViewController,
        sender: Any,
        onActionCompleted: @escaping (BottomToolbarAction) -> Void
    ) {
        switch type {
        case .download:
            nodeActionHandler.download(selectedNodes)
        case .shareLink:
            nodeActionHandler.shareOrManageLink(selectedNodes)
        case .move:
            nodeActionHandler.browserAction(.move, selectedNodes)
        case .copy:
            nodeActionHandler.browserAction(.copy, selectedNodes)
        case .delete:
            delete(
                displayMode: displayMode,
                for: selectedNodes
            )
        case .restore:
            nodeActionHandler.restore(selectedNodes)
        case .actions:
            presentMoreActions(
                displayMode: displayMode,
                for: selectedNodes,
                parent: parent,
                isIncomingShareChildView: isIncomingShareChildView,
                onActionCompleted: onActionCompleted,
                sender: sender
            )
        }
    }
    
    private func presentMoreActions(
        displayMode: DisplayMode,
        for nodes: [NodeEntity],
        parent: UIViewController,
        isIncomingShareChildView: Bool,
        onActionCompleted: @escaping (BottomToolbarAction) -> Void,
        sender: Any
    ) {
        
        let nodeActionsViewController = NodeActionViewController(
            nodes: megaNodes(from: nodes),
            delegate: nodeActionHandler,
            displayMode: displayMode,
            isIncoming: isIncomingShareChildView,
            containsABackupNode: displayMode == .backup,
            sender: sender
        )
        parent.present(nodeActionsViewController, animated: true, completion: nil)
    }
    
    private func delete(
        displayMode: DisplayMode,
        for nodes: [NodeEntity]
    ) {
        switch displayMode {
        case .cloudDrive:
            nodeActionHandler.moveToRubbishBin(nodes)
        case .rubbishBin:
            nodeActionHandler.removeFromRubbishBin(nodes)
        default: break
        }
    }
}
