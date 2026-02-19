import MEGAAppPresentation
import MEGADomain
import MEGAL10n
import MEGAUIComponent
import MEGAUIKit
import Search
import SwiftUI
import UIKit

@MainActor
final class FavouritesViewModel: ObservableObject {
    struct Dependency {
        let resultsProvider: any SearchResultsProviding
        let contextAction: @MainActor (HandleEntity, UIButton) -> Void

        init(
            resultsProvider: any SearchResultsProviding,
            contextAction: @escaping @MainActor (HandleEntity, UIButton) -> Void
        ) {
            self.resultsProvider = resultsProvider
            self.contextAction = contextAction
        }
    }

    @Published var viewMode: SearchResultsViewMode = .list

    lazy var searchResultsContainerViewModel: SearchResultsContainerViewModel = {
        let searchBridge = SearchBridge(
            selection: { _ in },
            context: { [weak self] result, button in
                self?.dependency.contextAction(result.id, button)
            },
            chipTapped: { _, _ in },
            sortingOrder: { .init(key: .name) },
            updateSortOrder: { _ in },
            chipPickerShowedHandler: { _ in }
        )

        searchBridge.viewModeChanged = { [weak self] viewMode in
            self?.handleViewModeChanged(viewMode)
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
            isSelectionEnabled: false,
            usesRevampedLayout: true,
            contentUnavailableViewModelProvider: FavouritesContentUnavailableProvider()
        )

        let containerVM = SearchResultsContainerViewModel(
            bridge: searchBridge,
            config: searchConfig,
            searchResultsViewModel: searchResultsViewModel,
            sortHeaderConfig: SortHeaderConfig(
                title: Strings.Localizable.sortTitle,
                options: [MEGAUIComponent.SortOrder.Key.name].sortOptions
            ),
            headerType: .dynamic,
            initialViewMode: viewMode,
            shouldShowMediaDiscoveryModeHandler: { false },
            sortHeaderViewPressedEvent: { }
        )

        return containerVM
    }()

    private let dependency: Dependency

    init(dependency: Dependency) {
        self.dependency = dependency
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
}
