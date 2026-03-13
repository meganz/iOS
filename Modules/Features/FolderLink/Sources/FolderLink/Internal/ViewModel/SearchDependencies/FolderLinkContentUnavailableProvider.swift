import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGASwiftUI
import Search

/// Provides the empty-state assets used in Search.
/// This references `CloudDriveContentUnavailableViewModelProvider`, but only
/// cherry-picks logic specific to Folder Links.
///
/// There are three scenarios:
/// - Search is inactive or no chips are applied: Assets representing an empty folder.
/// - Search query is empty and a `NodeFormat` chip is applied: Assets representing no results for the selected chips.
/// - All other cases: Assets representing no results in general.
struct FolderLinkContentUnavailableProvider: ContentUnavailableViewModelProviding {
    func emptyViewModel(
        query: Search.SearchQuery,
        appliedChips: [Search.SearchChipEntity],
        config: Search.SearchConfig
    ) -> ContentUnavailableViewModel {
        let searchIsActive = query.isSearchActive
        let hasSearchQuery = query.query.isNotEmpty
        let hasAppliedChips = appliedChips.isNotEmpty
        return switch (searchIsActive, hasSearchQuery, hasAppliedChips) {
        // no search or chips at all => show empty folder
        case (false, false, false):
            ContentUnavailableViewModel.emptyFolder
        // no search query but has chip applied => show chip-related empty
        case (_, false, true):
            if let nodeFormatChip = appliedChips.first(where: { $0.type.isNodeFormatChip || $0.type.isNodeTypeChip }) {
                ContentUnavailableViewModel.noResults(for: nodeFormatChip)
            } else {
                ContentUnavailableViewModel.noResults
            }
        // show no results
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
    
    static var emptyFolder: Self {
        ContentUnavailableViewModel(
            image: MEGAAssets.Image.cloudDriveEmptyStateNonRoot,
            title: Strings.Localizable.CloudDrive.EmptyStateTitle.nonRoot,
            subtitle: Strings.Localizable.CloudDrive.emptyStateSubtitle,
            font: .body, // Not used in revamped UI
            titleTextColor: .primary, // Not used in revamped UI
            actions: []
        )
    }
    
    static func noResults(for chip: SearchChipEntity) -> Self {
        let titleTextColor = TokenColors.Icon.secondary.swiftUI
        
        return switch chip.id {
            case SearchChipEntity.docs.id:
                ContentUnavailableViewModel(
                    image: MEGAAssets.Image.glassFile,
                    title: Strings.Localizable.Home.Search.Empty.noDocuments,
                    font: .body,
                    titleTextColor: titleTextColor
                )
            case SearchChipEntity.audio.id:
                ContentUnavailableViewModel(
                    image: MEGAAssets.Image.glassAudio,
                    title: Strings.Localizable.Home.Search.Empty.noAudio,
                    font: .body,
                    titleTextColor: titleTextColor
                )
            case SearchChipEntity.video.id:
                ContentUnavailableViewModel(
                    image: MEGAAssets.Image.glassVideo,
                    title: Strings.Localizable.Home.Search.Empty.noVideos,
                    font: .body,
                    titleTextColor: titleTextColor
                )
            case SearchChipEntity.images.id:
                ContentUnavailableViewModel(
                    image: MEGAAssets.Image.glassImage,
                    title: Strings.Localizable.Home.Search.Empty.noImages,
                    font: .body,
                    titleTextColor: titleTextColor
                )
            case SearchChipEntity.folders.id:
                ContentUnavailableViewModel(
                    image: MEGAAssets.Image.glassFolder,
                    title: Strings.Localizable.Home.Search.Empty.noFolders,
                    font: .body,
                    titleTextColor: titleTextColor
                )
            case SearchChipEntity.pdf.id:
                ContentUnavailableViewModel(
                    image: MEGAAssets.Image.glassFile,
                    title: Strings.Localizable.Home.Search.Empty.noPdfs,
                    font: .body,
                    titleTextColor: titleTextColor
                )
            case SearchChipEntity.presentation.id:
                ContentUnavailableViewModel(
                    image: MEGAAssets.Image.glassPlaylist,
                    title: Strings.Localizable.Home.Search.Empty.noPresentations,
                    font: .body,
                    titleTextColor: titleTextColor
                )
            case SearchChipEntity.archives.id:
                ContentUnavailableViewModel(
                    image: MEGAAssets.Image.glassObjects,
                    title: Strings.Localizable.Home.Search.Empty.noArchives,
                    font: .body,
                    titleTextColor: titleTextColor
                )
            case SearchChipEntity.spreadsheets.id:
                ContentUnavailableViewModel(
                    image: MEGAAssets.Image.glassFile,
                    title: Strings.Localizable.Home.Search.Empty.noSpreadsheets,
                    font: .body,
                    titleTextColor: titleTextColor
                )
            default:
                ContentUnavailableViewModel.noResults
            }
    }
}
