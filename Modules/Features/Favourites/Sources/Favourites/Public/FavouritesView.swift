import MEGADesignToken
import MEGADomain
import MEGAL10n
import Search
import SwiftUI

public struct FavouritesView: View {
    public struct Dependency {
        let fileSearchUseCase: any FilesSearchUseCaseProtocol
        let sensitiveDisplayPreferenceUseCase: any SensitiveDisplayPreferenceUseCaseProtocol
        let searchResultsMapper: any FavouritesSearchResultsMapping

        public init(
            fileSearchUseCase: some FilesSearchUseCaseProtocol,
            sensitiveDisplayPreferenceUseCase: some SensitiveDisplayPreferenceUseCaseProtocol,
            searchResultsMapper: some FavouritesSearchResultsMapping
        ) {
            self.fileSearchUseCase = fileSearchUseCase
            self.sensitiveDisplayPreferenceUseCase = sensitiveDisplayPreferenceUseCase
            self.searchResultsMapper = searchResultsMapper
        }
    }

    private let viewModel: FavouritesViewModel

    public init(dependency: Dependency) {
        viewModel = FavouritesViewModel(
            resultsProvider: FavouriteSearchResultsProvider(
                dependency: .init(
                    fileSearchUseCase: dependency.fileSearchUseCase,
                    sensitiveDisplayPreferenceUseCase: dependency.sensitiveDisplayPreferenceUseCase,
                    searchResultsMapper: dependency.searchResultsMapper
                )
            )
        )
    }

    public var body: some View {
        SearchResultsContainerView(viewModel: viewModel.searchResultsContainerViewModel)
            .background(TokenColors.Background.page.swiftUI)
            .navigationTitle(Strings.Localizable.Home.Favourites.title)
    }
}
