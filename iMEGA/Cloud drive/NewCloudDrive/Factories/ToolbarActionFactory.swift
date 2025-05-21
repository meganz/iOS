import MEGAAssets
import MEGADomain

// Those are actions with bar button items present in the toolbar
enum BottomToolbarAction {
    case download
    case shareLink
    case move
    case copy
    case delete
    case restore
    case actions
    
    var image: UIImage {
        switch self {
        case .download:
            MEGAAssets.UIImage.offline
        case .shareLink:
            MEGAAssets.UIImage.link
        case .move:
            MEGAAssets.UIImage.move
        case .copy:
            MEGAAssets.UIImage.copy
        case .delete:
            MEGAAssets.UIImage.rubbishBin
        case .restore:
            MEGAAssets.UIImage.restore
        case .actions:
            MEGAAssets.UIImage.moreNavigationBar
        }
    }
}

/// Protocol to be able to disconnect logic (and test separately) of what is actually placed from the creating UIBarButtonItems from the BottomToolbarAction values
protocol ToolbarActionFactoryProtocol {
    func buildActions(
        accessType: NodeAccessTypeEntity,
        isBackupNode: Bool,
        displayMode: DisplayMode
    ) -> [BottomToolbarAction]
}

/// This bit of logic only produces the actions enum for the given context
/// It's used by CloudDriveBottomToolbarItemsFactory to build actions and then turn them into UIBarButtonItems and add action handlers
/// but the logic what button is actually shown when is defined here
struct ToolbarActionFactory: ToolbarActionFactoryProtocol {
    
    func buildActions(
        accessType: NodeAccessTypeEntity,
        isBackupNode: Bool,
        displayMode: DisplayMode
    ) -> [BottomToolbarAction] {
        
        switch accessType {
        case .read, .readWrite:
            accessReadWriteActions(isBackupNode: isBackupNode)
        case .full:
            accessFullActions()
        case .owner:
            accessOwnerActions(displayMode: displayMode)
        default:
            []
        }
        
    }
    
    private func accessReadWriteActions(
        isBackupNode: Bool
    ) -> [BottomToolbarAction] {
        if isBackupNode {
            backupActions
        } else {
            [
                .download,
                .copy
            ]
        }
    }
    
    var backupActions: [BottomToolbarAction] {
        [
            .download,
            .shareLink,
            .actions
        ]
    }
    
    private func accessFullActions() -> [BottomToolbarAction] {
        [
            .download,
            .copy,
            .move,
            .delete
        ]
    }
    
    private func accessOwnerActions(
        displayMode: DisplayMode
    ) -> [BottomToolbarAction] {
        switch displayMode {
        case .cloudDrive:
            [
                .download,
                .shareLink,
                .move,
                .delete,
                .actions
            ]
        case .rubbishBin:
            [
                .restore,
                .delete
            ]
        case .backup:
            backupActions
        default:
            []
        }
    }
}
