import MEGADomain
import MEGAL10n

@MainActor
final class NodeDescriptionViewModel {
    enum SavedState: Equatable {
        case added
        case removed
        case updated

        var localizedString: String {
            switch self {
            case .added:
                return Strings.Localizable.CloudDrive.NodeInfo.NodeDescription.SavedState.descriptionAdded
            case .removed:
                return Strings.Localizable.CloudDrive.NodeInfo.NodeDescription.SavedState.descriptionRemoved
            case .updated:
                return Strings.Localizable.CloudDrive.NodeInfo.NodeDescription.SavedState.descriptionUpdated
            }
        }
    }
    
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
    private let nodeDescriptionUseCase: any NodeDescriptionUseCaseProtocol
    let descriptionSaved: (SavedState) -> Void
    
    var placeholderTextForReadWriteMode: String {
        Strings.Localizable.CloudDrive.NodeInfo.NodeDescription.EmptyText.readWrite
    }

    private var placeholderTextForReadOnlyMode: String {
        Strings.Localizable.CloudDrive.NodeInfo.NodeDescription.EmptyText.readOnly
    }

    var hasReadOnlyAccess: Bool {
        let nodeAccessLevel = nodeUseCase.nodeAccessLevel(nodeHandle: node.handle)

        return nodeUseCase.isInRubbishBin(nodeHandle: node.handle)
        || backupUseCase.isBackupNodeHandle(node.handle)
        || backupUseCase.isBackupsRootNode(node)
        || (nodeAccessLevel != .full && nodeAccessLevel != .owner)
    }

    var description: Description {
        guard let description = node.description, description.isNotEmpty else {
            return .placeholder(hasReadOnlyAccess ? placeholderTextForReadOnlyMode : placeholderTextForReadWriteMode)
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
        backupUseCase: some BackupsUseCaseProtocol,
        nodeDescriptionUseCase: some NodeDescriptionUseCaseProtocol,
        descriptionSaved: @escaping (SavedState) -> Void
    ) {
        self.node = node
        self.nodeUseCase = nodeUseCase
        self.backupUseCase = backupUseCase
        self.nodeDescriptionUseCase = nodeDescriptionUseCase
        self.descriptionSaved = descriptionSaved
    }

    func save(descriptionString: String) async {
        if let savedState = await update(descriptionString: descriptionString) {
            descriptionSaved(savedState)
        }
    }

    private func update(descriptionString: String) async -> SavedState? {
        do {
            let updatedDescriptionString = descriptionString.isEmpty ? nil : descriptionString
            let savedStatus = detectSavedState(for: updatedDescriptionString)
            node = try await nodeDescriptionUseCase.update(description: updatedDescriptionString, for: node)
            return savedStatus
        } catch {
            MEGALogError("Failed to update node \(node) with error \(error)")
            return nil
        }
    }

    private func detectSavedState(for descriptionString: String?) -> SavedState {
        if description.isPlaceholder, descriptionString != nil {
            return .added
        } else if descriptionString == nil {
            return .removed
        } else {
            return .updated
        }
    }
}
