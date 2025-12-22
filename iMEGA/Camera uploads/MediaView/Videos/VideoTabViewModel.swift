import Combine
import ContentLibraries
import MEGAAppPresentation
import MEGAAssets
import MEGADomain
import MEGAL10n
import SwiftUI
import Video

@MainActor
final class VideoTabViewModel: ObservableObject, MediaTabContentViewModel, MediaTabSharedResourceConsumer {
    let videoListViewModel: VideoListViewModel
    let videoSelection: VideoSelection
    let videoConfig: VideoConfig
    let router: any VideoRevampRouting
    private let syncModel: VideoRevampSyncModel
    private let featureFlagProvider: any FeatureFlagProviderProtocol
    private var subscriptions = Set<AnyCancellable>()

    // MARK: - MediaTabSharedResourceConsumer

    weak var sharedResourceProvider: (any MediaTabSharedResourceProvider)? {
        didSet {
            setupEditModeObservation()
        }
    }

    // MARK: - MediaTabToolbarActionHandler

    weak var toolbarCoordinator: (any MediaTabToolbarCoordinatorProtocol)?

    // MARK: - MediaTabContextMenuActionHandler

    let editModeToggleRequested = PassthroughSubject<Void, Never>()

    // MARK: - Initialization

    init(
        videoListViewModel: VideoListViewModel,
        videoSelection: VideoSelection,
        syncModel: VideoRevampSyncModel,
        videoConfig: VideoConfig,
        router: any VideoRevampRouting,
        featureFlagProvider: any FeatureFlagProviderProtocol
    ) {
        self.videoListViewModel = videoListViewModel
        self.videoSelection = videoSelection
        self.syncModel = syncModel
        self.videoConfig = videoConfig
        self.router = router
        self.featureFlagProvider = featureFlagProvider
    }

    // MARK: - Private Methods

    private func setupEditModeObservation() {
        guard let sharedResourceProvider else { return }

        sharedResourceProvider.editModePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newEditMode in
                guard let self else { return }
                let convertedEditMode: Video.EditMode = newEditMode == .active ? .active : .inactive
                self.syncModel.editMode = convertedEditMode
                self.videoSelection.editMode = convertedEditMode
             }
            .store(in: &subscriptions)
    }
}

// MARK: - MediaTabNavigationBarItemProvider

extension VideoTabViewModel: MediaTabNavigationBarItemProvider {
    func navigationBarItems(for editMode: SwiftUI.EditMode) -> [NavigationBarItemViewModel] {
        guard let sharedResourceProvider else { return [] }

        return if editMode == .active {
           editModeNavigationBarItems()
        } else {
           normalModeNavigationBarItems(sharedResourceProvider: sharedResourceProvider)
        }
    }

    private func normalModeNavigationBarItems(
        sharedResourceProvider: any MediaTabSharedResourceProvider
    ) -> [NavigationBarItemViewModel] {
        var items: [NavigationBarItemViewModel] = []

        // Camera upload status button
        items.append(MediaNavigationBarItemFactory.cameraUploadStatusButton(
            viewModel: sharedResourceProvider.cameraUploadStatusButtonViewModel
        ))

        // Search button
        items.append(MediaNavigationBarItemFactory.searchButton {

        })

        // Context menu button (trailing)
        if let config = sharedResourceProvider.contextMenuConfig,
           let manager = sharedResourceProvider.contextMenuManager {
            // Include filter and sort info in id so SwiftUI recreates the view when they change
            let locationFilter = config.selectedVideoLocationFilter?.rawValue ?? ""
            let durationFilter = config.selectedVideoDurationFilter?.rawValue ?? ""
            let sortType = config.sortType.map { String(describing: $0) } ?? ""
            let menuId = "context-menu-\(locationFilter)-\(durationFilter)-\(sortType)"

            items.append(
                NavigationBarItemViewModel(
                    id: menuId,
                    placement: .trailing,
                    type: .contextMenu(config: config, manager: manager)
                )
            )
        }

        return items
    }

    private func editModeNavigationBarItems() -> [NavigationBarItemViewModel] {
        [
            NavigationBarItemViewModel(
                id: "select-all",
                placement: .leading,
                type: .imageButton(
                    image: MEGAAssets.UIImage.selectAllItems,
                    action: { [weak self] in
                        self?.handleSelectAllAction()
                    }
                )
            ),
            NavigationBarItemViewModel(
                id: "cancel",
                placement: .trailing,
                type: .textButton(
                    text: Strings.localized("cancel", comment: ""),
                    action: { [weak self] in
                        self?.handleCancelAction()
                    }
                )
            )
        ]
    }

    private func handleSelectAllAction() {
        syncModel.isAllSelected.toggle()
    }

    private func handleCancelAction() {
        editModeToggleRequested.send()
    }
}

// MARK: - MediaTabContextMenuProvider

extension VideoTabViewModel: MediaTabContextMenuProvider {
    func contextMenuConfiguration() -> CMConfigEntity? {
        let selectedLocationFilter = videoListViewModel.selectedLocationFilterOption.toVideoLocationFilterEntity
        let selectedDurationFilter = videoListViewModel.selectedDurationFilterOption.toVideoDurationFilterEntity

        return CMConfigEntity(
            menuType: .menu(type: .mediaTabVideos),
            sortType: syncModel.videoRevampSortOrderType,
            isVideosRevampExplorer: true,
            isSelectHidden: false,
            isEmptyState: false,
            selectedVideoLocationFilter: selectedLocationFilter,
            selectedVideoDurationFilter: selectedDurationFilter
        )
    }
}

// MARK: - MediaTabContextMenuActionHandler

extension VideoTabViewModel: MediaTabContextMenuActionHandler {
    func handleDisplayAction(_ action: DisplayActionEntity) {
        switch action {
        case .select:
            editModeToggleRequested.send()
        default:
            break
        }
    }

    func handleSortAction(_ sortType: SortOrderType) {
        syncModel.videoRevampSortOrderType = sortType.toSortOrderEntity()
    }

    func handleVideoLocationFilter(_ filter: VideoLocationFilterEntity) {
        videoListViewModel.selectedLocationFilterOption = LocationChipFilterOptionType(from: filter)
    }

    func handleVideoDurationFilter(_ filter: VideoDurationFilterEntity) {
        videoListViewModel.selectedDurationFilterOption = DurationChipFilterOptionType(from: filter)
    }
}

// MARK: - MediaTabToolbarActionsProvider

extension VideoTabViewModel: MediaTabToolbarActionsProvider {
    var toolbarUpdatePublisher: AnyPublisher<Void, Never>? {
        videoSelection.$videos
            .map { $0.isEmpty }
            .removeDuplicates()
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    func toolbarConfig() -> MediaBottomToolbarConfig? {
        let selectedNodes = selectedNodesForToolbar
        let selectedCount = selectedNodes.count

        // Calculate export state
        let exportedNodes = selectedNodes.filter { $0.isExported }
        let isAllExported = selectedCount > 0 && exportedNodes.count == selectedCount

        // Define toolbar actions - always return actions even when no selection
        // The UI will handle button enabled/disabled state based on selectedItemsCount
        let actions: [MediaBottomToolbarAction] = [.download, .manageLink, .saveToPhotos, .sendToChat, .more]

        return MediaBottomToolbarConfig(
            actions: actions,
            selectedItemsCount: selectedCount,
            isAllExported: isAllExported
        )
    }

    /// Private helper to get selected nodes for internal use
    private var selectedNodesForToolbar: [NodeEntity] {
        videoSelection.videos.values
            .compactMap { $0 }
    }
}

// MARK: - MediaTabToolbarActionHandler

extension VideoTabViewModel: MediaTabToolbarActionHandler {
    func handleToolbarAction(_ action: MediaBottomToolbarAction) {
        // Get selected nodes and delegate to coordinator for UI operations
        let nodes = selectedNodesForToolbar
        guard !nodes.isEmpty else { return }

        toolbarCoordinator?.handleToolbarAction(action, with: nodes)
    }
}

// MARK: - MediaTabNavigationTitleProvider

extension VideoTabViewModel: MediaTabNavigationTitleProvider {
    var titleUpdatePublisher: AnyPublisher<String, Never> {
        let inactiveEditModeTitle = Strings.Localizable.Photos.SearchResults.Media.Section.title
        guard let sharedResourceProvider else {
            return Just(inactiveEditModeTitle).eraseToAnyPublisher()
        }

        let selectionCountPublisher = videoSelection.$videos
            .map { $0.count }
            .eraseToAnyPublisher()

        return sharedResourceProvider.selectionTitlePublisher(
            selectionCountPublisher: selectionCountPublisher,
            inactiveEditModeTitle: inactiveEditModeTitle)
    }
}
