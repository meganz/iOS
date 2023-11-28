import MEGAL10n
import Search
import SwiftUI

extension SearchConfig {
    static func searchConfig(contextPreviewFactory: ContextPreviewFactory) -> SearchConfig {
        .init(
            chipAssets: .init(
                selectionIndicatorImage: Asset.Images.Generic.turquoiseCheckmark.image,
                selectedForeground: .white,
                selectedBackground: Colors.Photos.filterTypeSelectionBackground.swiftUIColor,
                normalForeground: Colors.Photos.filterNormalTextForeground.swiftUIColor,
                normalBackground: Colors.Photos.filterTypeNormalBackground.swiftUIColor
            ),
            emptyViewAssetFactory: { chip in
                let textColor = Color(.gray515151)
                let defaultEmptyContent = EmptyViewAssets(
                    image: Asset.Images.EmptyStates.searchEmptyState.swiftUIImage,
                    title: Strings.Localizable.Home.Search.Empty.noChipSelected,
                    foregroundColor: textColor
                )
                guard let chip else {
                    return defaultEmptyContent
                }
                
                switch chip.id {
                case SearchChipEntity.docs.id:
                    return .init(
                        image: Asset.Images.Home.SearchResults.noResultsDocuments.swiftUIImage,
                        title: Strings.Localizable.Home.Search.Empty.noDocuments,
                        foregroundColor: textColor
                    )
                case SearchChipEntity.audio.id:
                    return .init(
                        image: Asset.Images.Home.SearchResults.noResultsAudio.swiftUIImage,
                        title: Strings.Localizable.Home.Search.Empty.noAudio,
                        foregroundColor: textColor
                    )
                case SearchChipEntity.video.id:
                    return .init(
                        image: Asset.Images.Home.SearchResults.noResultsVideo.swiftUIImage,
                        title: Strings.Localizable.Home.Search.Empty.noVideos,
                        foregroundColor: textColor
                    )
                case SearchChipEntity.images.id:
                    return .init(
                        image: Asset.Images.Home.SearchResults.noResultsImages.swiftUIImage,
                        title: Strings.Localizable.Home.Search.Empty.noImages,
                        foregroundColor: textColor
                    )
                case SearchChipEntity.folders.id:
                    return .init(
                        image: Asset.Images.Home.SearchResults.noResultsFolders.swiftUIImage,
                        title: Strings.Localizable.Home.Search.Empty.noFolders,
                        foregroundColor: textColor
                    )
                case SearchChipEntity.pdf.id:
                    return .init(
                        image: Asset.Images.Home.SearchResults.noResultsDocuments.swiftUIImage,
                        title: Strings.Localizable.Home.Search.Empty.noPdfs,
                        foregroundColor: textColor
                    )
                case SearchChipEntity.presentation.id:
                    return .init(
                        image: Asset.Images.Home.SearchResults.noResultsPresentations.swiftUIImage,
                        title: Strings.Localizable.Home.Search.Empty.noPresentations,
                        foregroundColor: textColor
                    )
                case SearchChipEntity.archives.id:
                    return .init(
                        image: Asset.Images.Home.SearchResults.noResultsArchives.swiftUIImage,
                        title: Strings.Localizable.Home.Search.Empty.noArchives,
                        foregroundColor: textColor
                    )
                default:
                    return defaultEmptyContent
                    
                }
            },
            rowAssets: .init(
                contextImage: Asset.Images.Generic.moreList.image,
                itemSelected: Asset.Images.Login.checkBoxSelected.image,
                itemUnselected: Asset.Images.Login.checkBoxUnselected.image,
                playImage: Asset.Images.Generic.videoList.image,
                downloadedImage: Asset.Images.Generic.downloaded.image,
                moreList: Asset.Images.Generic.moreList.image,
                moreGrid: Asset.Images.Generic.moreGrid.image
            ), 
            colorAssets: .init(
                F7F7F7: Color(.whiteF7F7F7),
                _161616: Colors.General.Black._161616.swiftUIColor,
                _545458: Colors.General.Gray._545458.swiftUIColor,
                CE0A11: Color.redCE0A11,
                F30C14: Color.redF30C14,
                F95C61: Color.redF95C61,
                F7363D: Color.redF7363D,
                _1C1C1E: Color(.black1C1C1E)
            ),
            contextPreviewFactory: contextPreviewFactory
        )
    }
}
