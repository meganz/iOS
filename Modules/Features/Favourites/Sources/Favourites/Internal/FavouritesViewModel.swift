import Combine
import MEGAAppPresentation
import MEGADomain
import MEGAL10n
import MEGAUIComponent
import MEGAUIKit
import Search
import SwiftUI
import UIKit

@MainActor
package final class FavouritesViewModel: ObservableObject {
    package struct Dependency {
        let resultsProvider: any SearchResultsProviding
        let sortOrderPreferenceUseCase: any SortOrderPreferenceUseCaseProtocol

        package init(
            resultsProvider: any SearchResultsProviding,
            sortOrderPreferenceUseCase: some SortOrderPreferenceUseCaseProtocol
        ) {
            self.resultsProvider = resultsProvider
            self.sortOrderPreferenceUseCase = sortOrderPreferenceUseCase
        }
    }

    @Published package var viewMode: SearchResultsViewMode = .list
    @Published package var editMode: EditMode = .inactive
    @Published package var selectedNodeHandles: Set<HandleEntity> = []
    @Published package var bottomBarAction: BottomBarAction?
    @Published package var nodesAction: NodesAction?
    @Published package var bottomBarDisabled: Bool = true
    @Published package var searchText: String = ""
    @Published package var searchBecameActive: Bool = false
    @Published package var selection: SearchResultSelection?
    @Published package var nodeAction: NodeAction?

    package lazy var searchResultsContainerViewModel: SearchResultsContainerViewModel = {
        let searchBridge = SearchBridge(
            selection: { [weak self] selection in
                self?.selection = selection
            },
            context: { [weak self] result, button in
                self?.nodeAction = .init(handle: result.id, sender: button)
            },
            chipTapped: { _, _ in },
            sortingOrder: { [dependency] in
                dependency.sortOrderPreferenceUseCase.sortOrder(for: .homeFavourites).toUIComponentSortOrderEntity()
            },
            updateSortOrder: { [dependency] in
                dependency.sortOrderPreferenceUseCase.save(sortOrder: $0.toDomainSortOrderEntity(), for: .homeFavourites)
            },
            chipPickerShowedHandler: { _ in }
        )

        searchBridge.viewModeChanged = { [weak self] viewMode in
            self?.handleViewModeChanged(viewMode)
        }

        searchBridge.editingChanged = { [weak self] editing in
            self?.editMode = editing ? .active : .inactive
        }

        searchBridge.selectionChanged = { [weak self] handles in
            self?.selectedNodeHandles = handles
        }

        let searchConfig = SearchConfig.favourites

        let searchResultsViewModel = SearchResultsViewModel(
            resultsProvider: dependency.resultsProvider,
            bridge: searchBridge,
            config: searchConfig,
            layout: .list,
            keyboardVisibilityHandler: KeyboardVisibilityHandler(notificationCenter: .default),
            viewDisplayMode: .favourites,
            listHeaderViewModel: nil,
            isSelectionEnabled: true,
            usesRevampedLayout: true,
            contentUnavailableViewModelProvider: FavouritesContentUnavailableProvider()
        )

        let containerVM = SearchResultsContainerViewModel(
            bridge: searchBridge,
            config: searchConfig,
            searchResultsViewModel: searchResultsViewModel,
            sortHeaderConfig: SortHeaderConfig(
                title: Strings.Localizable.sortTitle,
                options: [
                    MEGAUIComponent.SortOrder.Key.name,
                    .favourite,
                    .label,
                    .dateAdded,
                    .lastModified,
                    .size
                ].sortOptions
            ),
            headerType: .dynamic,
            initialViewMode: viewMode,
            shouldShowMediaDiscoveryModeHandler: { false },
            sortHeaderViewPressedEvent: { }
        )

        return containerVM
    }()

    private let dependency: Dependency
    private var subscriptions: Set<AnyCancellable> = []

    package init(dependency: Dependency) {
        self.dependency = dependency
        listenToSortOrderChanges()
        listenToEditingChanges()
        listenToBottomBarActions()
        listenToSelectionChanges()
        listenToSearchUpdates()
        listenToSearchActiveChanges()
    }

    package func exitEditMode() {
        withAnimation {
            editMode = .inactive
        }
    }

    package func toggleSelectAll() {
        searchResultsContainerViewModel.toggleSelectAll()
    }

    private func handleViewModeChanged(_ viewMode: SearchResultsViewMode) {
        guard self.viewMode != viewMode else { return }
        self.viewMode = viewMode
        switch viewMode {
        case .grid:
            searchResultsContainerViewModel.update(pageLayout: .thumbnail)
        case .list:
            searchResultsContainerViewModel.update(pageLayout: .list)
        case .mediaDiscovery:
            break // MD mode is not supported in favourites
        }
    }

    private func listenToSortOrderChanges() {
        dependency.sortOrderPreferenceUseCase
            .monitorSortOrder(for: .homeFavourites)
            .dropFirst()
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sortOrder in
                self?.searchResultsContainerViewModel.changeSortOrder(sortOrder.toUIComponentSortOrderEntity())
            }
            .store(in: &subscriptions)
    }

    private func listenToBottomBarActions() {
        $bottomBarAction
            .dropFirst()
            .compactMap { [weak self] action in
                guard let self, let action else { return nil }
                return switch action {
                case .download:
                    NodesAction.download(selectedNodeHandles)
                case .removeFavourite:
                    NodesAction.toggleFavourites(selectedNodeHandles)
                case .shareLink:
                    NodesAction.shareLink(selectedNodeHandles)
                case .moveToRubbishBin:
                    NodesAction.moveToRubbishBin(selectedNodeHandles)
                case .more:
                    NodesAction.more(selectedNodeHandles)
                }
            }
            .assign(to: &$nodesAction)
    }

    private func listenToEditingChanges() {
        $editMode
            .dropFirst()
            .removeDuplicates()
            .sink { [weak self] mode in
                guard let self else { return }
                let isEditing = mode.isEditing
                searchResultsContainerViewModel.setEditing(isEditing)
                if !isEditing {
                    searchResultsContainerViewModel.clearSelection()
                    selectedNodeHandles = []
                    bottomBarAction = nil
                }
            }
            .store(in: &subscriptions)
    }

    private func listenToSelectionChanges() {
        $selectedNodeHandles
            .combineLatest($editMode)
            .map { nodes, editMode in
                guard editMode == .active else { return true }
                return nodes.isEmpty
            }
            .assign(to: &$bottomBarDisabled)
    }
    
    private func listenToSearchUpdates() {
        Publishers
            .CombineLatest($searchText, $searchBecameActive)
            .removeDuplicates { lhs, rhs in
                lhs.0 == rhs.0 && lhs.1 == rhs.1
            }
            .sink { [searchResultsContainerViewModel] text, isActive in
                if !isActive, text.isEmpty {
                    searchResultsContainerViewModel.bridge.queryCleaned()
                } else {
                    searchResultsContainerViewModel.bridge.queryChanged(text)
                }
            }
            .store(in: &subscriptions)
    }
    
    private func listenToSearchActiveChanges() {
        $searchBecameActive
            .removeDuplicates()
            .dropFirst()
            .sink { [searchResultsContainerViewModel] isActive in
                searchResultsContainerViewModel.searchActiveDidChange(isActive)
            }
            .store(in: &subscriptions)
    }
}
