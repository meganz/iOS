import MEGAAppSDKRepo
import MEGADomain
import MEGAL10n

class CloudDriveNavigationTitleBuilder {
    static func build(
        parentNode: NodeEntity?,
        isEditModeActive: Bool,
        displayMode: DisplayMode,
        selectedNodesArrayCount: Int,
        nodes: NodeListEntity?,
        backupsUseCase: any BackupsUseCaseProtocol
    ) -> String {
        if isEditModeActive {
            return editingTitle(selectedNodesArrayCount: selectedNodesArrayCount)
        } else {
            return regularTitle(
                parentNode: parentNode,
                displayMode: displayMode,
                nodes: nodes,
                backupsUseCase: backupsUseCase
            )
        }
    }

    private static func regularTitle(
        parentNode: NodeEntity?,
        displayMode: DisplayMode,
        nodes: NodeListEntity?,
        backupsUseCase: any BackupsUseCaseProtocol
    ) -> String {
        switch displayMode {
        case .cloudDrive:
            makeCloudDriveTitle(parentNode: parentNode)
        case .rubbishBin:
            makeRubbishBinTitle(parentNode: parentNode)
        case .backup:
            makeBackupsTitle(parentNode: parentNode, backupsUseCase: backupsUseCase)
        case .recents:
            makeRecentsTitle(nodesCount: nodes?.nodesCount ?? 0)
        default:
            ""
        }
    }

    private static func makeCloudDriveTitle(parentNode: NodeEntity?) -> String {
        parentNode == nil || parentNode?.nodeType == .root ? Strings.Localizable.cloudDrive : parentNode?.name ?? ""
    }

    private static func makeRubbishBinTitle(parentNode: NodeEntity?) -> String {
        parentNode?.nodeType == .rubbish ? Strings.Localizable.rubbishBinLabel : parentNode?.name ?? ""
    }

    private static func makeBackupsTitle(parentNode: NodeEntity?, backupsUseCase: any BackupsUseCaseProtocol) -> String {
        let isBackupsNode = parentNode != nil ? backupsUseCase.isBackupsRootNode(parentNode!) : false
        return isBackupsNode ? Strings.Localizable.Backups.title : parentNode?.name ?? ""
    }

    static func makeRecentsTitle(nodesCount: Int) -> String {
        return Strings.Localizable.Recents.Section.Title.items(nodesCount)
    }

    private static func editingTitle(selectedNodesArrayCount: Int) -> String {
        selectedNodesArrayCount == 0 ? Strings.Localizable.selectTitle : Strings.Localizable.General.Format.itemsSelected(selectedNodesArrayCount)
    }
}
