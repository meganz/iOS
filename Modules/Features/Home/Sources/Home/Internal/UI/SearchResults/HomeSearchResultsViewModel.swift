import Combine
import MEGAAppPresentation
import MEGAUIComponent
import MEGAUIKit
import Search
import UIKit

@MainActor
final class HomeSearchResultsViewModel: ObservableObject {
    struct Dependency {
        let searchConfig: SearchConfig
        let resultsProvider: any SearchResultsProviding
        let pageLayout: PageLayout
    }

    @Published var searchText: String = ""
    @Published var searchBecameActive: Bool = false

    @Published package var selection: NodeSelection?
    @Published package var nodeAction: NodeAction?
    private let dependency: Dependency

    package lazy var searchResultsContainerViewModel: SearchResultsContainerViewModel = {

        let searchBridge = SearchBridge(
            selection: { [weak self] in
                self?.selection = NodeSelection(handle: $0.result.id, siblings: $0.siblings())
            },
            context: { [weak self] in
                self?.nodeAction = .init(handle: $0.id, sender: $1)
            },
            chipTapped: { _, _ in },
            sortingOrder: {  .init(key: .name) }, // for home search we only allow .name sorting
            updateSortOrder: { _ in }, // Home search doesn't allow updating sort order
            chipPickerShowedHandler: { _ in
                // [IOS-11393]: [Home Search] Handle analytics tracking
            }
        )

        let searchResultsViewModel = SearchResultsViewModel(
            resultsProvider: dependency.resultsProvider,
            bridge: searchBridge,
            config: dependency.searchConfig,
            layout: dependency.pageLayout,
            keyboardVisibilityHandler: KeyboardVisibilityHandler(notificationCenter: .default),
            viewDisplayMode: .folderLink,
            listHeaderViewModel: nil,
            isSelectionEnabled: true,
            usesRevampedLayout: true,
            contentUnavailableViewModelProvider: HomeScreenContentUnavailableViewModelProvider()
        )

        let sortHeaderConfig = SortHeaderConfig(title: "", options: [MEGAUIComponent.SortOrder.Key.name.sortOption])

        return SearchResultsContainerViewModel(
            bridge: searchBridge,
            config: dependency.searchConfig,
            searchResultsViewModel: searchResultsViewModel,
            sortHeaderConfig: sortHeaderConfig,
            headerType: .chips,
            initialViewMode: .list,
            shouldShowMediaDiscoveryModeHandler: { false },
            sortHeaderViewPressedEvent: {}
        )
    }()

    private var cancellables: Set<AnyCancellable> = []
    init(dependency: Dependency) {
        self.dependency = dependency
        configureBindings()
    }

    private func configureBindings() {
        $searchText
            .sink { [searchResultsContainerViewModel] text in
                searchResultsContainerViewModel.bridge.queryChanged(text)
            }
            .store(in: &cancellables)
    }
}
