import MEGADesignToken
import MEGAL10n
import Search
import SwiftUI

public struct FavouritesView: View {
    private let viewModel: FavouritesViewModel

    public init() {
        viewModel = FavouritesViewModel(
            resultsProvider: FavouriteSearchResultsProvider()
        )
    }

    public var body: some View {
        SearchResultsContainerView(viewModel: viewModel.searchResultsContainerViewModel)
            .background(TokenColors.Background.page.swiftUI)
            .navigationTitle(Strings.Localizable.Home.Favourites.title)
    }
}
