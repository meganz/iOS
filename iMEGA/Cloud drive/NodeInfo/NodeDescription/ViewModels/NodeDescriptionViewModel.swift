import MEGADomain
import MEGAL10n

final class NodeDescriptionViewModel {
    enum Description: Equatable {
        case content(String)
        case placeholder(String)

        var text: String {
            switch self {
            case .content(let text): return text
            case .placeholder(let text): return text
            }
        }

        var isPlaceholder: Bool {
            guard case .placeholder = self else { return false }
            return true
        }
    }

    private(set) var node: NodeEntity
    private let nodeUseCase: any NodeUseCaseProtocol
    private let backupUseCase: any BackupsUseCaseProtocol

    var hasReadOnlyAccess: Bool {
        let nodeAccessLevel = nodeUseCase.nodeAccessLevel(nodeHandle: node.handle)

        return nodeUseCase.isInRubbishBin(nodeHandle: node.handle)
        || backupUseCase.isBackupNodeHandle(node.handle)
        || backupUseCase.isBackupsRootNode(node)
        || (nodeAccessLevel != .full && nodeAccessLevel != .owner)
    }

    var description: Description {
        guard let description = node.description, description.isNotEmpty else {
            return hasReadOnlyAccess
            ? .placeholder(Strings.Localizable.CloudDrive.NodeInfo.NodeDescription.EmptyText.readOnly)
            : .placeholder(Strings.Localizable.CloudDrive.NodeInfo.NodeDescription.EmptyText.readWrite)
        }

        return .content(description)
    }

    var header: String {
        Strings.Localizable.CloudDrive.NodeInfo.NodeDescription.header
    }

    var footer: String? {
        hasReadOnlyAccess
        ? Strings.Localizable.CloudDrive.NodeInfo.NodeDescription.readonly
        : nil
    }

    init(
        node: NodeEntity,
        nodeUseCase: some NodeUseCaseProtocol,
        backupUseCase: some BackupsUseCaseProtocol
    ) {
        self.node = node
        self.nodeUseCase = nodeUseCase
        self.backupUseCase = backupUseCase
    }

    func updateNode(node: NodeEntity) {
        self.node = node
    }
}
