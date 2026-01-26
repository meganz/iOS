import Combine
import MEGADomain
import MEGAL10n
import MEGAUIComponent
import MEGAUIKit
import Search
import SwiftUI
import UIKit

@MainActor
final class FolderLinkResultsViewModel: ObservableObject {
    struct Dependency {
        let nodeHandle: HandleEntity
        let link: String
        let searchResultMapper: any FolderLinkSearchResultMapperProtocol
        let titleUseCase: any FolderLinkTitleUseCaseProtocol
        let viewModeUseCase: any FolderLinkViewModeUseCaseProtocol
        let searchUseCase: any FolderLinkSearchUseCaseProtocol
        let editModeUseCase: any FolderLinkEditModeUseCaseProtocol
        let bottomBarUseCase: any FolderLinkBottomBarUseCaseProtocol
        let quickActionUseCase: any FolderLinkQuickActionUseCaseProtocol
        let sortOrderPreferenceUseCase: any SortOrderPreferenceUseCaseProtocol
    }

    @Published var editMode: EditMode = .inactive
    @Published var searchText: String = ""
    @Published var searchBecameActive: Bool = false
    @Published var selection: SearchResultSelection?
    @Published var nodeAction: FolderLinkNodeAction?
    @Published var nodesAction: FolderLinkNodesAction?
    @Published var quickAction: FolderLinkQuickAction?
    @Published var bottomBarAction: FolderLinkBottomBarAction?
    @Published var bottomBarDisabled: Bool = true
    @Published var shouldIncludeSaveToPhotosBottomAction: Bool = false
    @Published var title: String = ""
    @Published var subtitle: String?
    
    var shouldShowQuickActionsMenu: Bool {
        dependency.quickActionUseCase.shouldEnableQuickActions(for: dependency.nodeHandle)
    }
    
    var shouldEnableMediaDiscoveryMode: Bool {
        dependency.viewModeUseCase.shouldEnableMediaDiscoveryMode(for: dependency.nodeHandle)
    }
    
    var shouldEnableMoreOptionsMenu: Bool {
        dependency.editModeUseCase.canEnterEditModeWhenOpeningFolder(dependency.nodeHandle)
    }
    
    lazy var searchResultsContainerViewModel: SearchResultsContainerViewModel = {
        let searchBridge = SearchBridge { [weak self] selection in
            self?.selection = selection
        } context: { [weak self] result, button in
            self?.nodeAction = FolderLinkNodeAction(handle: result.id, sender: button)
        } chipTapped: { chip, selected in
            print(chip, selected)
        } sortingOrder: { [sortOrder] in
            sortOrder
        } updateSortOrder: { [weak self] sortOrder in
            self?.sortOrder = sortOrder
        } chipPickerShowedHandler: { searchChipEntity in
            print(searchChipEntity)
        }
        
        searchBridge.viewModeChanged = { [weak self] viewMode in
            self?.handleViewModeChanged(viewMode)
        }
        
        searchBridge.selectionChanged = { [weak self] results in
            self?.selectedNodes = results
        }
        
        searchBridge.editingChanged = { [weak self] editing in
            self?.editMode = editing ? .active : .inactive
        }
        
        let searchResultsProvider = FolderLinkSearchResultsProvider(
            nodeHandle: dependency.nodeHandle,
            searchChips: SearchChipEntity.allChips(currentDate: { .init() }, calendar: .autoupdatingCurrent),
            folderLinkSearchUseCase: dependency.searchUseCase,
            folderSearchResultMapper: dependency.searchResultMapper
        )
        
        let searchConfig = SearchConfig.folderLink
        
        let searchResultsViewModel = SearchResultsViewModel(
            resultsProvider: searchResultsProvider,
            bridge: searchBridge,
            config: searchConfig,
            layout: viewMode == .grid ? .thumbnail : .list,
            keyboardVisibilityHandler: KeyboardVisibilityHandler(notificationCenter: .default),
            viewDisplayMode: .folderLink,
            listHeaderViewModel: nil,
            isSelectionEnabled: true,
            usesRevampedLayout: true,
            contentUnavailableViewModelProvider: FolderLinkContentUnavailableProvider()
        )
        
        return SearchResultsContainerViewModel(
            bridge: searchBridge,
            config: searchConfig,
            searchResultsViewModel: searchResultsViewModel,
            sortHeaderConfig: SortHeaderConfig.folderLink,
            headerType: .dynamic,
            initialViewMode: viewMode,
            shouldShowMediaDiscoveryModeHandler: { [weak self] in self?.shouldEnableMediaDiscoveryMode ?? false },
            sortHeaderViewPressedEvent: { } // IOS-11083
        )
    }()
    
    private let dependency: FolderLinkResultsViewModel.Dependency
    private var cancellables: Set<AnyCancellable> = []
    
    @Binding var viewMode: SearchResultsViewMode
    @Published private var sortOrder: MEGAUIComponent.SortOrder
    @Published private var selectedNodes: Set<HandleEntity> = []
    
    init(
        dependency: FolderLinkResultsViewModel.Dependency,
        viewMode: Binding<SearchResultsViewMode>
    ) {
        self.dependency = dependency
        self._viewMode = viewMode
        sortOrder = dependency.sortOrderPreferenceUseCase.sortOrder(for: dependency.nodeHandle).toUIComponentSortOrderEntity()
        
        $nodesAction
            .compactMap { $0 }
            .sink { [weak self] _ in
                self?.editMode = .inactive
            }
            .store(in: &cancellables)
        
        $editMode
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] mode in
                guard let self else { return }
                let isEditing = mode.isEditing
                switch self.viewMode {
                case .list, .grid:
                    searchResultsContainerViewModel.setEditing(isEditing)
                    if !isEditing {
                        searchResultsContainerViewModel.clearSelection()
                    }
                case .mediaDiscovery:
                    break
                }
            }
            .store(in: &cancellables)
        
        $sortOrder
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] order in
                guard let self else { return }
                dependency.sortOrderPreferenceUseCase.save(sortOrder: order.toDomainSortOrderEntity(), for: dependency.nodeHandle)
                searchResultsContainerViewModel.changeSortOrder(order)
            }
            .store(in: &cancellables)    
        
        /// Disable the bottom bar when editMode is active, and no nodes is selected
        $selectedNodes
            .combineLatest($editMode)
            .map { nodes, editMode in
                dependency.bottomBarUseCase.shouldDisableBottomBar(
                    handle: dependency.nodeHandle,
                    editingState: editMode.isEditing ? .active(nodes) : .inactive
                )
            }
            .assign(to: &$bottomBarDisabled)
        
        $selectedNodes
            .combineLatest($editMode)
            .map { nodes, editMode in
                dependency.bottomBarUseCase.shouldIncludeSaveToPhotosAction(
                    handle: dependency.nodeHandle,
                    editingState: editMode.isEditing ? .active(nodes) : .inactive
                )
            }
            .assign(to: &$shouldIncludeSaveToPhotosBottomAction)
        
        $quickAction
            .compactMap { $0 }
            .map { action in
                switch action {
                case .addToCloudDrive:
                    FolderLinkNodesAction.addToCloudDrive([dependency.nodeHandle])
                case .makeAvailableOffline:
                    FolderLinkNodesAction.makeAvailableOffline([dependency.nodeHandle])
                case .sendToChat:
                    FolderLinkNodesAction.sendToChat(dependency.link)
                }
            }
            .assign(to: &$nodesAction)
        
        $bottomBarAction
            .compactMap { $0 }
            .compactMap { [weak self] action in
                guard let self else { return nil }
                let nodes = editMode.isEditing ? selectedNodes : [dependency.nodeHandle]
                return switch action {
                case .addToCloudDrive:
                    FolderLinkNodesAction.addToCloudDrive(nodes)
                case .makeAvailableOffline:
                    FolderLinkNodesAction.makeAvailableOffline(nodes)
                case .saveToPhotos:
                    FolderLinkNodesAction.saveToPhotos(nodes)
                }
            }
            .assign(to: &$nodesAction)
        
        $selectedNodes
            .combineLatest($editMode)
            .map { nodes, editMode in
                dependency.titleUseCase.title(
                    for: dependency.nodeHandle,
                    editingState: editMode.isEditing ? .active(nodes) : .inactive
                )
            }.sink { [weak self] type in
                switch type {
                case .askForSelecting:
                    self?.title = Strings.Localizable.selectTitle
                    self?.subtitle = nil
                case let .folderNodeName(name):
                    self?.title = name
                    self?.subtitle = Strings.Localizable.folderLink
                case let .selectedItems(count):
                    self?.title = Strings.Localizable.General.Format.itemsSelected(count)
                    self?.subtitle = nil
                case .undecryptedFolder:
                    self?.title = Strings.Localizable.SharedItems.Tab.Incoming.undecryptedFolderName
                    self?.subtitle = Strings.Localizable.folderLink
                case .generic:
                    self?.title = Strings.Localizable.folderLink
                    self?.subtitle = nil
                }
            }
            .store(in: &cancellables)
        
        $searchText
            .sink { [searchResultsContainerViewModel] text in
                searchResultsContainerViewModel.bridge.queryChanged(text)
            }
            .store(in: &cancellables)
        
        $searchBecameActive
            .sink { [searchResultsContainerViewModel] isActive in
                searchResultsContainerViewModel.searchActiveDidChange(isActive)
            }
            .store(in: &cancellables)
    }
    
    /// edit mode of Search and MediaDiscovery is independent so here we only handle for list and grid view mode.
    /// For mediaDiscovery view mode, it is handled in FolderLinkMediaDiscoveryViewModel
    func toggleSelectAll() {
        switch viewMode {
        case .list, .grid:
            searchResultsContainerViewModel.toggleSelectAll()
        case .mediaDiscovery:
            break
        }
    }
    
    /// When the viewMode is changed to list or grid, we ask Search to update the page layout accordantly,
    /// For mediaDiscovery mode, we do nothing but update the binding viewMode so the parent knows and switch to media discovery view
    private func handleViewModeChanged(_ viewMode: SearchResultsViewMode) {
        guard self.viewMode != viewMode else { return }
        self.viewMode = viewMode
        switch viewMode {
        case .grid:
            searchResultsContainerViewModel.update(pageLayout: .thumbnail)
        case .list:
            searchResultsContainerViewModel.update(pageLayout: .list)
        case .mediaDiscovery:
            break
        }
    }
}
