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
            if let nodeFormatChip = appliedChips.first(where: { $0.type.isNodeFormatChip }) {
                ContentUnavailableViewModel.noResults(for: nodeFormatChip)
            } else {
                ContentUnavailableViewModel.noResults
            }
        default:
            ContentUnavailableViewModel.noResults
        }
    }
}

fileprivate extension ContentUnavailableViewModel {
    static var noResults: Self {
        ContentUnavailableViewModel(
            image: MEGAAssets.Image.glassSearch02,
            title: Strings.Localizable.noResults,
            font: .body,
            titleTextColor: TokenColors.Icon.secondary.swiftUI
        )
    }
    
    static var noFavourites: Self {
        ContentUnavailableViewModel(
            image: MEGAAssets.Image.glassHearts,
            title: Strings.Localizable.noFavourites,
            font: .body,
            titleTextColor: TokenColors.Icon.secondary.swiftUI
        )
    }
    
    static func noResults(for chip: SearchChipEntity) -> Self {
        switch chip.id {
        case SearchChipEntity.docs.id:
            ContentUnavailableViewModel(
                image: MEGAAssets.Image.glassFile,
                title: Strings.Localizable.Home.Search.Empty.noDocuments,
                font: .body,
                titleTextColor: TokenColors.Icon.secondary.swiftUI
            )
        case SearchChipEntity.audio.id:
            ContentUnavailableViewModel(
                image: MEGAAssets.Image.glassAudio,
                title: Strings.Localizable.Home.Search.Empty.noAudio,
                font: .body,
                titleTextColor: TokenColors.Icon.secondary.swiftUI
            )
        case SearchChipEntity.video.id:
            ContentUnavailableViewModel(
                image: MEGAAssets.Image.glassVideo,
                title: Strings.Localizable.Home.Search.Empty.noVideos,
                font: .body,
                titleTextColor: TokenColors.Icon.secondary.swiftUI
            )
        case SearchChipEntity.images.id:
            ContentUnavailableViewModel(
                image: MEGAAssets.Image.glassImage,
                title: Strings.Localizable.Home.Search.Empty.noImages,
                font: .body,
                titleTextColor: TokenColors.Icon.secondary.swiftUI
            )
        case SearchChipEntity.folders.id:
            ContentUnavailableViewModel(
                image: MEGAAssets.Image.glassFolder,
                title: Strings.Localizable.Home.Search.Empty.noFolders,
                font: .body,
                titleTextColor: TokenColors.Icon.secondary.swiftUI
            )
        case SearchChipEntity.pdf.id:
            ContentUnavailableViewModel(
                image: MEGAAssets.Image.glassFile,
                title: Strings.Localizable.Home.Search.Empty.noPdfs,
                font: .body,
                titleTextColor: TokenColors.Icon.secondary.swiftUI
            )
        case SearchChipEntity.presentation.id:
            ContentUnavailableViewModel(
                image: MEGAAssets.Image.glassPlaylist,
                title: Strings.Localizable.Home.Search.Empty.noPresentations,
                font: .body,
                titleTextColor: TokenColors.Icon.secondary.swiftUI
            )
        case SearchChipEntity.archives.id:
            ContentUnavailableViewModel(
                image: MEGAAssets.Image.glassObjects,
                title: Strings.Localizable.Home.Search.Empty.noArchives,
                font: .body,
                titleTextColor: TokenColors.Icon.secondary.swiftUI
            )
        case SearchChipEntity.spreadsheets.id:
            ContentUnavailableViewModel(
                image: MEGAAssets.Image.glassFile,
                title: Strings.Localizable.Home.Search.Empty.noSpreadsheets,
                font: .body,
                titleTextColor: TokenColors.Icon.secondary.swiftUI
            )
        default:
            ContentUnavailableViewModel.noResults
        }
    }
}
