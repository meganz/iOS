import Combine
import ContentLibraries
import MEGAAppPresentation
import MEGAAssets
import MEGADomain
import MEGAL10n
import SwiftUI
import Video

@MainActor
final class VideoTabViewModel: ObservableObject, @MainActor MediaTabInteractiveProvider {
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
             }
            .store(in: &subscriptions)
    }
}

// MARK: - MediaTabNavigationBarItemProvider

extension VideoTabViewModel {
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

extension VideoTabViewModel {
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

extension VideoTabViewModel {
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

extension VideoTabViewModel {
    func toolbarActions(
        selectedItemsCount: Int,
        hasExportedItems: Bool,
        isAllExported: Bool
    ) -> [MediaBottomToolbarAction]? {
        guard selectedItemsCount > 0 else { return nil }

        // For now, return nil as we'll implement video-specific toolbar actions later
        // The original implementation uses a custom toolbar in UIKit
        return nil
    }
}

// MARK: - MediaTabToolbarActionHandler

extension VideoTabViewModel {
    func handleToolbarAction(_ action: MediaBottomToolbarAction) {
        // This will be implemented when we migrate from the UIKit toolbar
    }
}
