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
        backupsUseCase: any BackupsUseCaseProtocol,
        sdk: MEGASdk = MEGASdk.shared
    ) -> String {
        if isEditModeActive {
            editingTitle(selectedNodesArrayCount: selectedNodesArrayCount)
        } else {
            regularTitle(
                parentNode: parentNode,
                displayMode: displayMode,
                nodes: nodes,
                backupsUseCase: backupsUseCase,
                sdk: sdk
            )
        }
    }

    private static func regularTitle(
        parentNode: NodeEntity?,
        displayMode: DisplayMode,
        nodes: NodeListEntity?,
        backupsUseCase: any BackupsUseCaseProtocol,
        sdk: MEGASdk
    ) -> String {
        switch displayMode {
        case .cloudDrive:
            makeCloudDriveTitle(parentNode: parentNode, sdk: sdk)
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

    private static func makeCloudDriveTitle(parentNode: NodeEntity?, sdk: MEGASdk) -> String {
        parentNode == nil || parentNode?.nodeType == .root
        ? Strings.Localizable.cloudDrive
        : nameAfterDecryptionCheck(for: parentNode, sdk: sdk) ?? ""
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

    private static func nameAfterDecryptionCheck(for node: NodeEntity?, sdk: MEGASdk) -> String? {
        guard let handle = node?.handle else { return nil }
        return sdk.node(forHandle: handle)?.nameAfterDecryptionCheck()
    }
}
