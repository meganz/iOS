import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import Search

/// Provides the empty-state assets used in Search for Favourites.
///
/// There are three scenarios:
/// - Search is inactive or no chips are applied: Assets representing no favourites.
/// - Search query is empty and a `NodeFormat` chip is applied: Assets representing no results for the selected chips.
/// - All other cases: Assets representing no results in general.
struct FavouritesContentUnavailableProvider: ContentUnavailableViewModelProviding {
    func emptyViewModel(
        query: Search.SearchQuery,
        appliedChips: [Search.SearchChipEntity],
        config: Search.SearchConfig
    ) -> ContentUnavailableViewModel {
        return switch (query.isSearchActive, query.query.isNotEmpty, appliedChips.isNotEmpty) {
        case (false, false, false):
            ContentUnavailableViewModel.noFavourites
        case (_, false, true):
            if let nodeFormatChip = appliedChips.first(where: { $0.type.isNodeFormatChip || $0.type.isNodeTypeChip }) {
                noResults(for: nodeFormatChip)
            } else {
                ContentUnavailableViewModel.noResults
            }
        default:
            ContentUnavailableViewModel.noResults
        }
    }
    
    private func noResults(for chip: SearchChipEntity) -> ContentUnavailableViewModel {
        switch chip.id {
        case SearchChipEntity.docs.id:
                .noDocs
        case SearchChipEntity.audio.id:
                .noAudios
        case SearchChipEntity.video.id:
                .noVideos
        case SearchChipEntity.images.id:
                .noImages
        case SearchChipEntity.folders.id:
                .noFolders
        case SearchChipEntity.pdf.id:
                .noPdfs
        case SearchChipEntity.presentation.id:
                .noPresentations
        case SearchChipEntity.archives.id:
                .noArchives
        case SearchChipEntity.spreadsheets.id:
                .noSpreadSheets
        default:
                .noResults
        }
    }
}

fileprivate extension ContentUnavailableViewModel {
    static var noFavourites: Self {
        ContentUnavailableViewModel(
            image: MEGAAssets.Image.glassHearts,
            title: Strings.Localizable.noFavourites,
            font: .body,
            titleTextColor: TokenColors.Icon.secondary.swiftUI
        )
    }
}
