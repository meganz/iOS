import MEGAL10n
import MEGASwiftUI
import Search

struct HomeScreenContentUnavailableViewModelProvider: ContentUnavailableViewModelProviding {
    func emptyViewModel(
        query: SearchQuery,
        appliedChips: [SearchChipEntity],
        config: SearchConfig
    ) -> ContentUnavailableViewModel {
        return switch (query.isSearchActive, query.query.isNotEmpty, appliedChips.isNotEmpty) {
        case (false, false, false):
                .noResults
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
