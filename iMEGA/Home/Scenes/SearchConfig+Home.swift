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
                F7F7F7: Color(.whiteF7F7F7),
                _161616: Color.black161616,
                _545458: Color.gray545458,
                CE0A11: Color.redCE0A11,
                F30C14: Color.redF30C14,
                F95C61: Color.redF95C61,
                F7363D: Color.redF7363D,
                _1C1C1E: Color(.black1C1C1E),
                _00A886: Color(.green00A886),
                _3C3C43: MEGAAppColor.Gray._3C3C43.color
            ),
            contextPreviewFactory: contextPreviewFactory
        )
    }
}
