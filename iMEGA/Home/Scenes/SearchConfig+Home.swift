import MEGAL10n
import Search
import SwiftUI

extension SearchConfig {
    static func searchConfig(contextPreviewFactory: ContextPreviewFactory) -> SearchConfig {
        .init(
            chipAssets: .init(
                selectionIndicatorImage: UIImage.turquoiseCheckmark,
                selectedForeground: .white,
                selectedBackground: Color.photosFilterTypeSelectionBackground,
                normalForeground: Color.photosFilterNormalTextForeground,
                normalBackground: Color.photosFilterTypeNormalBackground
            ),
            emptyViewAssetFactory: { chip in
                let textColor = Color(.gray515151)
                let defaultEmptyContent = EmptyViewAssets(
                    image: Image(.searchEmptyState),
                    title: Strings.Localizable.Home.Search.Empty.noChipSelected,
                    foregroundColor: textColor
                )
                guard let chip else {
                    return defaultEmptyContent
                }
                
                switch chip.id {
                case SearchChipEntity.docs.id:
                    return .init(
                        image: Image(.noResultsDocuments),
                        title: Strings.Localizable.Home.Search.Empty.noDocuments,
                        foregroundColor: textColor
                    )
                case SearchChipEntity.audio.id:
                    return .init(
                        image: Image(.noResultsAudio),
                        title: Strings.Localizable.Home.Search.Empty.noAudio,
                        foregroundColor: textColor
                    )
                case SearchChipEntity.video.id:
                    return .init(
                        image: Image(.noResultsVideo),
                        title: Strings.Localizable.Home.Search.Empty.noVideos,
                        foregroundColor: textColor
                    )
                case SearchChipEntity.images.id:
                    return .init(
                        image: Image(.noResultsImages),
                        title: Strings.Localizable.Home.Search.Empty.noImages,
                        foregroundColor: textColor
                    )
                case SearchChipEntity.folders.id:
                    return .init(
                        image: Image(.noResultsFolders),
                        title: Strings.Localizable.Home.Search.Empty.noFolders,
                        foregroundColor: textColor
                    )
                case SearchChipEntity.pdf.id:
                    return .init(
                        image: Image(.noResultsDocuments),
                        title: Strings.Localizable.Home.Search.Empty.noPdfs,
                        foregroundColor: textColor
                    )
                case SearchChipEntity.presentation.id:
                    return .init(
                        image: Image(.noResultsPresentations),
                        title: Strings.Localizable.Home.Search.Empty.noPresentations,
                        foregroundColor: textColor
                    )
                case SearchChipEntity.archives.id:
                    return .init(
                        image: Image(.noResultsArchives),
                        title: Strings.Localizable.Home.Search.Empty.noArchives,
                        foregroundColor: textColor
                    )
                default:
                    return defaultEmptyContent
                    
                }
            },
            rowAssets: .init(
                contextImage: UIImage.moreList,
                itemSelected: UIImage.checkBoxSelected,
                itemUnselected: UIImage.checkBoxUnselected,
                playImage: UIImage.videoList,
                downloadedImage: UIImage.downloaded,
                moreList: UIImage.moreList,
                moreGrid: UIImage.moreGrid
            ), 
            colorAssets: .init(
                F7F7F7: MEGAAppColor.White._F7F7F7.color,
                _161616: MEGAAppColor.Black._161616.color,
                _545458: MEGAAppColor.Gray._545458.color,
                CE0A11: MEGAAppColor.Red._CE0A11.color,
                F30C14: MEGAAppColor.Red._F30C14.color,
                F95C61: MEGAAppColor.Red._F95C61.color,
                F7363D: MEGAAppColor.Red._F7363D.color,
                _1C1C1E: MEGAAppColor.Black._1C1C1E.color,
                _00A886: MEGAAppColor.Green._00A8868.color,
                _3C3C43: MEGAAppColor.Gray._3C3C43.color
            ),
            contextPreviewFactory: contextPreviewFactory
        )
    }
}
