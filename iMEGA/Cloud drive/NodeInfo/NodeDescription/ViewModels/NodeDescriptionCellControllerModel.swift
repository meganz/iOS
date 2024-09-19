import MEGAAnalyticsiOS
import MEGADomain
import MEGAL10n
import MEGAPresentation

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

    struct Description: Equatable {
        let content: String?

        var isPlaceholder: Bool {
            content == nil || content == ""
        }
    }

    private let maxCharactersAllowed: Int
    private let tracker: any AnalyticsTracking
    private let textViewEdgeInsets = UIEdgeInsets(top: 11, left: 16, bottom: 11, right: 16)
    private let nodeUseCase: any NodeUseCaseProtocol
    private let backupUseCase: any BackupsUseCaseProtocol
    private let nodeDescriptionUseCase: any NodeDescriptionUseCaseProtocol
    private let networkMonitorUseCase: any NetworkMonitorUseCaseProtocol
    private let refreshUI: ((_ code: () -> Void) -> Void)
    let descriptionSaved: (SavedState) -> Void

    private(set) var node: NodeEntity
    
    /// Indicates whether the description text is being focused
    /// This is needed  for handling the footer state when node is updated
    private var isEditing: Bool {
        footerViewModel.trailingText != nil
    }
    
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

    var hasReadOnlyAccess: Bool {
        let nodeAccessLevel = nodeUseCase.nodeAccessLevel(nodeHandle: node.handle)

        return nodeUseCase.isInRubbishBin(nodeHandle: node.handle)
        || backupUseCase.isBackupNodeHandle(node.handle)
        || backupUseCase.isBackupsRootNode(node)
        || (nodeAccessLevel != .full && nodeAccessLevel != .owner)
    }

    var description: Description {
        .init(content: node.description)
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
        description: description.content ?? "",
        maxCharactersAllowed: maxCharactersAllowed
    )

    private(set) lazy var cellViewModel: NodeDescriptionCellViewModel = {
        NodeDescriptionCellViewModel(
            maxCharactersAllowed: maxCharactersAllowed,
            editingDisabled: { [weak self] in self?.hasReadOnlyAccess == true },
            textViewEdgeInsets: textViewEdgeInsets,
            descriptionProvider: { [weak self] in
                guard let self else { return nil }
                return description
            }, hasReadOnlyAccess: { [weak self] in
                self?.hasReadOnlyAccess == true
            }, descriptionUpdated: { [weak self] text in
                guard let self else { return }
                descriptionUpdated(text)
            }, saveDescription: { [weak self] description in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    await saveDescriptionIfNeeded(description)
                }
            }, isTextViewFocused: { [weak self] focused in
                guard let self else { return }
                focused ? showCharacterCountAndScrollToCell() : hideCharacterCount()
            }
        )
    }()

    init(
        node: NodeEntity,
        nodeUseCase: some NodeUseCaseProtocol,
        backupUseCase: some BackupsUseCaseProtocol,
        nodeDescriptionUseCase: some NodeDescriptionUseCaseProtocol,
        networkMonitorUseCase: some NetworkMonitorUseCaseProtocol,
        maxCharactersAllowed: Int = 300,
        tracker: some AnalyticsTracking = DIContainer.tracker,
        refreshUI: @escaping ((_ code: () -> Void) -> Void),
        descriptionSaved: @escaping (SavedState) -> Void
    ) {
        self.node = node
        self.nodeUseCase = nodeUseCase
        self.backupUseCase = backupUseCase
        self.nodeDescriptionUseCase = nodeDescriptionUseCase
        self.networkMonitorUseCase = networkMonitorUseCase
        self.maxCharactersAllowed = maxCharactersAllowed
        self.tracker = tracker
        self.refreshUI = refreshUI
        self.descriptionSaved = descriptionSaved
        self.hasPendingChanges = { false }
        self.savePendingChanges = { nil }
    }
    
    private func descriptionUpdated(_ text: String) {
        updateFooterViewAndScrollIfNeeded(with: text)
        updateHasPendingChanges(with: text)
        updateSavePendingChanges(with: text)
    }
    
    func updateDescription(with node: NodeEntity) {
        self.node = node
        let description = node.description ?? ""
        updateFooterView(description: description)
        updateHasPendingChanges(with: description)
        updateSavePendingChanges(with: description)
        cellViewModel.onUpdate?()
    }
    
    private func updateFooterView(description: String) {
        footerViewModel.description = description
        footerViewModel.leadingText = footer
        if hasReadOnlyAccess {
            footerViewModel.trailingText = nil
        } else if isEditing {
            footerViewModel.showTrailingText()
        } else {
            footerViewModel.trailingText = nil
        }
    }

    private func update(descriptionString: String) async -> SavedState {
        guard networkMonitorUseCase.isConnected() else { return .error }
        
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
        trackSaveResult(savedState: savedState)
    }

    private func updateFooterViewAndScrollIfNeeded(with text: String) {
        refreshUIAndScrollIfNeeded { [weak self] in
            guard let self else { return }
            updateFooterView(description: text)
        }
    }

    private func updateHasPendingChanges(with text: String) {
        hasPendingChanges = { [weak self] in
            guard let self else { return false }
            // When description is nil or "" and text is also empty, there's no pending changes.
            return description.isPlaceholder ? text.isNotEmpty : text != description.content
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
    
    private func trackSaveResult(savedState: SavedState) {
        guard let event = savedState.analyticEvent else { return }
        
        tracker.trackAnalyticsEvent(with: event)
    }
}

extension NodeDescriptionCellControllerModel.SavedState {
    var analyticEvent: (any EventIdentifier)? {
        switch self {
        case .added:
            NodeInfoDescriptionAddedMessageDisplayedEvent()
        case .updated:
            NodeInfoDescriptionUpdatedMessageDisplayedEvent()
        case .removed:
            NodeInfoDescriptionRemovedMessageDisplayedEvent()
        case .error:
            nil
        }
    }
}
