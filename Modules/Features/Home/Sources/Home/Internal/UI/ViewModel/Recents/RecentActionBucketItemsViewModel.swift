import Combine
import MEGAAppPresentation
import MEGADomain
import MEGAUIComponent
import MEGAUIKit
import Search
import SwiftUI

@MainActor
final class RecentActionBucketItemsViewModel: ObservableObject {
    struct Dependency {
        let nodes: [NodeEntity]
        let resultMapper: any RecentActionBucketItemResultMapping
    }
    
    @Published var editMode: EditMode = .inactive
    @Published var selection: NodeSelection?
    @Published var nodeAction: NodeAction?
    
    private let dependency: Dependency
    private var cancellables: Set<AnyCancellable> = []

    package lazy var searchResultsContainerViewModel: SearchResultsContainerViewModel = {
        let searchBridge = SearchBridge { [weak self] in
            self?.selection = NodeSelection(handle: $0.result.id, siblings: $0.siblings())
        } context: { [weak self] result, button in
            self?.nodeAction = NodeAction(handle: result.id, sender: button)
        } chipTapped: { _, _ in }
        sortingOrder: {
            SortOrder(key: .name, direction: .ascending)
        } updateSortOrder: { _ in }
        chipPickerShowedHandler: { _ in }
        
        searchBridge.selectionChanged = { results in
            print(results)
        }
        
        searchBridge.editingChanged = { [weak self] editing in
            self?.editMode = editing ? .active : .inactive
        }
        
        let searchConfig = SearchConfig.recentAction
        
        let searchResultsViewModel = SearchResultsViewModel(
            resultsProvider: RecentActionBucketItemsProvider(nodes: dependency.nodes, resultMapper: dependency.resultMapper),
            bridge: searchBridge,
            config: searchConfig,
            layout: .list,
            keyboardVisibilityHandler: KeyboardVisibilityHandler(notificationCenter: .default),
            viewDisplayMode: .recents,
            listHeaderViewModel: nil,
            isSelectionEnabled: true,
            usesRevampedLayout: true,
            contentUnavailableViewModelProvider: RecentActionBucketItemsContentUnvailableProvider()
        )
        
        return SearchResultsContainerViewModel(
            bridge: searchBridge,
            config: searchConfig,
            searchResultsViewModel: searchResultsViewModel,
            sortHeaderConfig: .recentAction,
            headerType: .none,
            initialViewMode: .list,
            shouldShowMediaDiscoveryModeHandler: { false },
            sortHeaderViewPressedEvent: {}
        )
    }()
    
    func toggleSelectAll() {
        searchResultsContainerViewModel.toggleSelectAll()
    }

    init(dependency: Dependency) {
        self.dependency = dependency
        
        $editMode
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] mode in
                guard let self else { return }
                let isEditing = mode.isEditing
                searchResultsContainerViewModel.setEditing(isEditing)
                if !isEditing {
                    searchResultsContainerViewModel.clearSelection()
                }
            }
            .store(in: &cancellables)
    }
}
