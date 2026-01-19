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
    @Published var selection: SearchResultSelection?
    @Published var nodeAction: FolderLinkNodeAction?
    @Published var nodesAction: FolderLinkNodesAction?
    @Published var quickAction: FolderLinkQuickAction?
    @Published var bottomBarAction: FolderLinkBottomBarAction?
    @Published var bottomBarDisabled: Bool = true
    @Published var shouldIncludeSaveToPhotosBottomAction: Bool = false
    
    // IOS-11084 - handle edit mode
    var title: String {
        switch dependency.titleUseCase.title(for: dependency.nodeHandle) {
        case let .named(value):
            value
        case .file:
            Strings.Localizable.SharedItems.Tab.Recents.undecryptedFileName(1)
        case .folder:
            Strings.Localizable.SharedItems.Tab.Incoming.undecryptedFolderName
        case .unknown:
            Strings.Localizable.folderLink
        }
    }
    
    var subtitle: String {
        Strings.Localizable.folderLink
    }
    
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
            guard let self, self.viewMode != viewMode else { return }
            self.viewMode = viewMode
        }
        
        searchBridge.selectionChanged = { [weak self] results in
            self?.selectedNodes = results
        }
        
        searchBridge.editingChanged = { [weak self] editing in
            self?.editMode = editing ? .active : .inactive
        }
        
        let searchResultsProvider = FolderLinkSearchResultsProvider(
            nodeHandle: dependency.nodeHandle,
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
            sortOptionsViewModel: SortOptionsViewModel.folderLink,
            headerType: .dynamic,
            initialViewMode: viewMode,
            shouldShowMediaDiscoveryModeHandler: { [weak self] in self?.shouldEnableMediaDiscoveryMode ?? false },
            sortHeaderViewPressedEvent: { } // IOS-11083
        )
    }()
    
    private let dependency: FolderLinkResultsViewModel.Dependency
    private var cancellables: Set<AnyCancellable> = []
    
    @Published private var sortOrder: MEGAUIComponent.SortOrder
    @Published private var viewMode: SearchResultsViewMode
    @Published private var selectedNodes: Set<HandleEntity> = []
    
    init(dependency: FolderLinkResultsViewModel.Dependency) {
        self.dependency = dependency
        
        sortOrder = dependency.sortOrderPreferenceUseCase.sortOrder(for: dependency.nodeHandle).toUIComponentSortOrderEntity()
        viewMode = dependency.viewModeUseCase.viewModeForOpeningFolder(dependency.nodeHandle)
        
        $viewMode
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] viewMode in
                guard let self else { return }
                switch viewMode {
                case .grid:
                    searchResultsContainerViewModel.update(pageLayout: .thumbnail)
                case .list:
                    searchResultsContainerViewModel.update(pageLayout: .list)
                case .mediaDiscovery:
                    // IOS-11103
                    break
                }
            }
            .store(in: &cancellables)
        
        $editMode
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] mode in
                guard let self else { return }
                searchResultsContainerViewModel.setEditing(mode.isEditing)
                if !mode.isEditing {
                    searchResultsContainerViewModel.clearSelection()
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
    }
}
