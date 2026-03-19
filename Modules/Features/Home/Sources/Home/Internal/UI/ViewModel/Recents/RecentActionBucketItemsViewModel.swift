import Combine
import MEGAAppPresentation
import MEGADomain
import MEGAL10n
import MEGAUIComponent
import MEGAUIKit
import Search
import SwiftUI

@MainActor
final class RecentActionBucketItemsViewModel: ObservableObject {
    struct Dependency {
        let bucket: RecentActionBucketEntity
        let resultMapper: any RecentActionBucketItemResultMapping
        var titleUseCase: any RecentActionBucketItemsTitleUseCaseProtocol = RecentActionBucketItemsTitleUseCase()
    }

    @Published var editMode: EditMode = .inactive
    @Published var selection: NodeSelection?
    @Published var nodeAction: NodeAction?
    @Published var navigationTitle: String = ""
    @Published var navigationSubtitle: String?
    @Published private var selectedNodes: Set<HandleEntity> = []

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
        
        searchBridge.selectionChanged = { [weak self] results in
            self?.selectedNodes = results
        }
        
        searchBridge.editingChanged = { [weak self] editing in
            self?.editMode = editing ? .active : .inactive
        }
        
        let searchConfig = SearchConfig.recentAction
        
        let searchResultsViewModel = SearchResultsViewModel(
            resultsProvider: RecentActionBucketItemsProvider(bucket: dependency.bucket, resultMapper: dependency.resultMapper),
            bridge: searchBridge,
            config: searchConfig,
            layout: .list,
            keyboardVisibilityHandler: KeyboardVisibilityHandler(notificationCenter: .default),
            viewDisplayMode: .recents,
            listHeaderViewModel: nil,
            isSelectionEnabled: true,
            usesRevampedLayout: true,
            contentUnavailableViewModelProvider: RecentActionBucketItemsContentUnavailableProvider()
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

        $selectedNodes
            .combineLatest($editMode)
            .map { [dependency] nodes, mode in
                dependency.titleUseCase.title(
                    for: dependency.bucket,
                    editingState: mode.isEditing ? .active(selectedCount: nodes.count) : .inactive
                )
            }
            .sink { [weak self] result in
                guard let self else { return }
                navigationTitle = switch result.title {
                case let .all(count):
                    Strings.Localizable.General.Format.Count.file(count)
                case let .selected(count):
                    Strings.Localizable.General.Format.itemsSelected(count)
                }
                
                navigationSubtitle = switch result.subtitle {
                case let .addedBy(parentName):
                    Strings.Localizable.Home.Recent.addedByLabel(parentName)
                case .none:
                    nil
                }
            }
            .store(in: &cancellables)
    }
}
