import MEGAAppPresentation
import MEGADomain
import MEGAL10n
import MEGAUIComponent
import MEGAUIKit
import Search
import SwiftUI
import UIKit

@MainActor
final class FavouritesViewModel {
    lazy var searchResultsContainerViewModel: SearchResultsContainerViewModel = {
        let searchBridge = SearchBridge(
            selection: { _ in },
            context: { _, _ in },
            chipTapped: { _, _ in },
            sortingOrder: { .init(key: .name) },
            updateSortOrder: { _ in },
            chipPickerShowedHandler: { _ in }
        )

        let searchConfig = SearchConfig.favourites

        let searchResultsViewModel = SearchResultsViewModel(
            resultsProvider: resultsProvider,
            bridge: searchBridge,
            config: searchConfig,
            layout: .list,
            keyboardVisibilityHandler: KeyboardVisibilityHandler(notificationCenter: .default),
            viewDisplayMode: .home,
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
            initialViewMode: .list,
            shouldShowMediaDiscoveryModeHandler: { false },
            sortHeaderViewPressedEvent: { }
        )

        return containerVM
    }()

    private let resultsProvider: any SearchResultsProviding

    init(
        resultsProvider: some SearchResultsProviding,
    ) {
        self.resultsProvider = resultsProvider
    }
}
