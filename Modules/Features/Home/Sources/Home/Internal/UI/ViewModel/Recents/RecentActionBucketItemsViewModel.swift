import Combine
import MEGAAppPresentation
import MEGADomain
import MEGAL10n
import MEGASwiftUI
import MEGAUIComponent
import MEGAUIKit
import Search
import SwiftUI

@MainActor
final class RecentActionBucketItemsViewModel: ObservableObject {
    struct Dependency {
        let bucket: RecentActionBucketEntity
        let resultMapper: any RecentActionBucketItemResultMapping
        let downloadedNodesListener: any DownloadedNodesListening
        let titleUseCase: any RecentActionBucketItemsTitleUseCaseProtocol = RecentActionBucketItemsTitleUseCase()
    }

    @Published var bottomBarAction: RecentActionBottomBarAction?
    @Published var editMode: EditMode = .inactive
    @Published private(set) var selection: NodeSelection?
    @Published private(set) var nodeAction: NodeAction?
    @Published private(set) var nodesAction: NodesAction?
    @Published private(set) var navigationTitle: String = ""
    @Published private(set) var navigationSubtitle: String?
    @Published private(set) var selectedNodes: Set<HandleEntity> = []
    @Published private(set) var isBucketEmpty: Bool = false
    @Published private(set) var fileNoLongerAvailableSnackBar: SnackBar?

    private let dependency: Dependency
    private var cancellables: Set<AnyCancellable> = []

    private let bucketItemsUpdateUseCase: any RecentActionBucketItemsUpdateUseCaseProtocol

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
            resultsProvider: RecentActionBucketItemsProvider(bucketId: dependency.bucket.id, resultMapper: dependency.resultMapper, downloadedNodesListener: dependency.downloadedNodesListener),
            bridge: searchBridge,
            config: searchConfig,
            layout: .list,
            keyboardVisibilityHandler: KeyboardVisibilityHandler(notificationCenter: .default),
            viewDisplayMode: .recents,
            listHeaderViewModel: nil,
            isSelectionEnabled: true,
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

    init(
        dependency: Dependency,
        bucketItemsUpdateUseCase: some RecentActionBucketItemsUpdateUseCaseProtocol = RecentActionBucketItemsUpdateUseCase()
    ) {
        self.dependency = dependency
        self.bucketItemsUpdateUseCase = bucketItemsUpdateUseCase

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

        $bottomBarAction
            .compactMap { [weak self] action in
                guard let action, let self else { return nil }
                return action.toNodesAction(handles: selectedNodes)
            }
            .assign(to: &$nodesAction)
        
        $nodesAction
            .compactMap { $0 }
            .sink { [weak self] _ in
                self?.editMode = .inactive
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
                case let .addedBy(parentName, nodesCount):
                    Strings.Localizable.Recents.BucketDetails.subtitle(nodesCount)
                        .replacingOccurrences(of: "[A]", with: parentName)
                case .none:
                    nil
                }
            }
            .store(in: &cancellables)
    }

    func toggleSelectAll() {
        searchResultsContainerViewModel.toggleSelectAll()
    }
    
    func observeEmptyItemsEvent() async {
        let unavailableUpdate = await bucketItemsUpdateUseCase
            .bucketUpdates(forId: dependency.bucket.id)
            .first { @Sendable in $0 == RecentActionBucketUpdatesEntity.unavailable }
        // `first(where:)` returns nil both when `.unavailable` fires AND when the
        // stream just ends — including when our task is cancelled (e.g. "Show in
        // location" pushes Cloud Drive over this screen). Guarding here stops us
        // from treating that cancellation as an empty bucket and wrongly bouncing
        // the user out with a "files no longer available" snackbar.
        guard unavailableUpdate != nil else { return }
        isBucketEmpty = true
        fileNoLongerAvailableSnackBar = SnackBar(message: Strings.Localizable.Home.Recent.MixedFileBucket.Snackbar.filesNotAvailable)
    }
}
