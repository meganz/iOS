import MEGAAssets
import MEGADesignToken
import MEGAL10n
import Search
import SwiftUI

extension SearchConfig {
    static func searchConfig(
        defaultEmptyViewAsset: @escaping () -> EmptyViewAssets
    ) -> SearchConfig {
        .init(
            emptyViewAssetFactory: { chip, query in
                let titleTextColor = TokenColors.Icon.secondary.swiftUI
                
                guard let chip else {
                    guard !query.isSearchActive else {
                        return searchEmptyState(with: titleTextColor)
                    }
                    
                    return defaultEmptyViewAsset()
                }
                
                switch chip.id {
                case SearchChipEntity.docs.id:
                    return .init(
                        image: MEGAAssets.Image.glassFile,
                        title: Strings.Localizable.Home.Search.Empty.noDocuments,
                        titleTextColor: titleTextColor
                    )
                case SearchChipEntity.audio.id:
                    return .init(
                        image: MEGAAssets.Image.glassAudio,
                        title: Strings.Localizable.Home.Search.Empty.noAudio,
                        titleTextColor: titleTextColor
                    )
                case SearchChipEntity.video.id:
                    return .init(
                        image: MEGAAssets.Image.glassVideo,
                        title: Strings.Localizable.Home.Search.Empty.noVideos,
                        titleTextColor: titleTextColor
                    )
                case SearchChipEntity.images.id:
                    return .init(
                        image: MEGAAssets.Image.glassImage,
                        title: Strings.Localizable.Home.Search.Empty.noImages,
                        titleTextColor: titleTextColor
                    )
                case SearchChipEntity.folders.id:
                    return .init(
                        image: MEGAAssets.Image.glassFolder,
                        title: Strings.Localizable.Home.Search.Empty.noFolders,
                        titleTextColor: titleTextColor
                    )
                case SearchChipEntity.pdf.id:
                    return .init(
                        image: MEGAAssets.Image.glassFile,
                        title: Strings.Localizable.Home.Search.Empty.noPdfs,
                        titleTextColor: titleTextColor
                    )
                case SearchChipEntity.presentation.id:
                    return .init(
                        image: MEGAAssets.Image.glassPlaylist,
                        title: Strings.Localizable.Home.Search.Empty.noPresentations,
                        titleTextColor: titleTextColor
                    )
                case SearchChipEntity.archives.id:
                    return .init(
                        image: MEGAAssets.Image.glassObjects,
                        title: Strings.Localizable.Home.Search.Empty.noArchives,
                        titleTextColor: titleTextColor
                    )
                case SearchChipEntity.spreadsheets.id:
                    return .init(
                        image: MEGAAssets.Image.glassFile,
                        title: Strings.Localizable.Home.Search.Empty.noSpreadsheets,
                        titleTextColor: titleTextColor
                    )
                default:
                    break
                }
                
                switch chip.type {
                case .timeFrame:
                    return searchEmptyState(with: titleTextColor)
                default:
                    return defaultEmptyViewAsset()
                }
            }
        )
    }
    
    private static func searchEmptyState(
        with titleTextColor: Color
    ) -> SearchConfig.EmptyViewAssets {
        .init(
            image: MEGAAssets.Image.glassSearch02,
            title: Strings.Localizable.Home.Search.Empty.noChipSelected,
            titleTextColor: titleTextColor
        )
    }
}
