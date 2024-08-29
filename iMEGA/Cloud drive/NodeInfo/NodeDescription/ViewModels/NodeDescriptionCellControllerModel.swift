import MEGADomain
import MEGAL10n

@MainActor
final class NodeDescriptionCellControllerModel {
    enum SavedState: Equatable {
        case added
        case removed
        case updated
        case error

        var localizedString: String {
            switch self {
            case .added:
                return Strings.Localizable.CloudDrive.NodeInfo.NodeDescription.SavedState.descriptionAdded
            case .removed:
                return Strings.Localizable.CloudDrive.NodeInfo.NodeDescription.SavedState.descriptionRemoved
            case .updated:
                return Strings.Localizable.CloudDrive.NodeInfo.NodeDescription.SavedState.descriptionUpdated
            case .error:
                return Strings.Localizable.CloudDrive.NodeInfo.NodeDescription.SavedState.error
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

    private let maxCharactersAllowed: Int
    private let textViewEdgeInsets = UIEdgeInsets(top: 11, left: 16, bottom: 11, right: 16)
    private(set) var node: NodeEntity
    private let nodeUseCase: any NodeUseCaseProtocol
    private let backupUseCase: any BackupsUseCaseProtocol
    private let nodeDescriptionUseCase: any NodeDescriptionUseCaseProtocol
    private let refreshUI: ((_ code: () -> Void) -> Void)
    let descriptionSaved: (SavedState) -> Void

    /// A closure that checks if there are any pending description changes that is not saved yet.
    ///
    /// - Returns: `true` if there are pending changes, otherwise `false`.
    var hasPendingChanges: () -> Bool

    /// A closure that asynchronously saves pending description changes and returns the save result.
    ///
    /// - Returns: An optional `SavedState` indicating the result of the save operation (`.added`,
    ///   `.removed`, `.updated`, or `.error`). If it returns nil, it means there are no unsaved changes.
    ///
    var savePendingChanges: () async -> SavedState?

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

    var scrollToCell: (() -> Void)?

    private(set) lazy var footerViewModel = NodeDescriptionFooterViewModel(
        leadingText: footer,
        description: description.isPlaceholder ? "" : description.text,
        maxCharactersAllowed: maxCharactersAllowed
    )

    private(set) lazy var cellViewModel: NodeDescriptionCellViewModel = {
        NodeDescriptionCellViewModel(
            maxCharactersAllowed: maxCharactersAllowed,
            editingDisabled: hasReadOnlyAccess,
            placeholderText: placeholderTextForReadWriteMode,
            textViewEdgeInsets: textViewEdgeInsets
        ) { [weak self] in
            guard let self else { return nil }
            return description
        } descriptionUpdated: { [weak self] text in
            guard let self else { return }
            descriptionUpdated(text)
        } saveDescription: { [weak self] description in
            Task { @MainActor [weak self] in
                guard let self else { return }
                await saveDescriptionIfNeeded(description)
            }
        } isTextViewFocused: { [weak self] focused in
            guard let self else { return }
            focused ? showCharacterCountAndScrollToCell() : hideCharacterCount()
        }
    }()

    init(
        node: NodeEntity,
        nodeUseCase: some NodeUseCaseProtocol,
        backupUseCase: some BackupsUseCaseProtocol,
        nodeDescriptionUseCase: some NodeDescriptionUseCaseProtocol,
        maxCharactersAllowed: Int = 300,
        refreshUI: @escaping ((_ code: () -> Void) -> Void),
        descriptionSaved: @escaping (SavedState) -> Void
    ) {
        self.node = node
        self.nodeUseCase = nodeUseCase
        self.backupUseCase = backupUseCase
        self.nodeDescriptionUseCase = nodeDescriptionUseCase
        self.maxCharactersAllowed = maxCharactersAllowed
        self.refreshUI = refreshUI
        self.descriptionSaved = descriptionSaved
        self.hasPendingChanges = { false }
        self.savePendingChanges = { nil }
    }

    private func update(descriptionString: String) async -> SavedState {
        do {
            let updatedDescriptionString = descriptionString.isEmpty ? nil : descriptionString
            let savedStatus = detectSavedState(for: updatedDescriptionString)
            node = try await nodeDescriptionUseCase.update(description: updatedDescriptionString, for: node)
            return savedStatus
        } catch {
            MEGALogError("Failed to update node \(node) with error \(error)")
            return .error
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

    private func refreshUIAndScrollIfNeeded(_ updates: () -> Void) {
        refreshUI {
            updates()
        }
        guard footerViewModel.trailingText != nil else { return }
        scrollToCell?()
    }

    private func saveDescriptionIfNeeded(_ description: String) async {
        guard let savedState = await savePendingChanges() else { return }
        descriptionSaved(savedState)
    }

    private func descriptionUpdated(_ text: String) {
        updateFooterViewAndScrollIfNeeded(with: text)
        updateHasPendingChanges(with: text)
        updateSavePendingChanges(with: text)
    }

    private func updateFooterViewAndScrollIfNeeded(with text: String) {
        refreshUIAndScrollIfNeeded {
            self.footerViewModel.description = text
            self.footerViewModel.showTrailingText()
        }
    }

    private func updateHasPendingChanges(with text: String) {
        hasPendingChanges = { [weak self] in
            guard let self else { return false }
            guard description.isPlaceholder, text.isNotEmpty else { return text != description.text }
            return true
        }
    }

    private func updateSavePendingChanges(with text: String) {
        savePendingChanges = { [weak self] in
            guard let self, hasPendingChanges() else { return nil }
            return await update(descriptionString: text)
        }
    }

    private func showCharacterCountAndScrollToCell() {
        footerViewModel.showTrailingText()
        scrollToCell?()
    }

    private func hideCharacterCount() {
        footerViewModel.trailingText = nil
    }
}
