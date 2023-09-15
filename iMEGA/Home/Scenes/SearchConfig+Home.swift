import MEGAL10n
import Search
import SwiftUI

extension SearchConfig {
    static var searchConfig: SearchConfig {
        .init(
            chipAssets: .init(
                selectedForeground: .white,
                selectedBackground: Colors.Photos.filterTypeSelectionBackground.swiftUIColor,
                normalForeground: Colors.Photos.filterNormalTextForeground.swiftUIColor,
                normalBackground: Colors.Photos.filterTypeNormalBackground.swiftUIColor
            ),
            emptyViewAssetFactory: { chip in
                let textColor = Colors.General.Gray._515151.swiftUIColor
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
                default:
                    return defaultEmptyContent
                    
                }
            },
            rowAssets: .init(
                contextImage: Asset.Images.Generic.moreList.image
            )
        )
    }
}
