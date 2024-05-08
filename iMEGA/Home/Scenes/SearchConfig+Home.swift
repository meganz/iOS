import MEGADesignToken
import MEGAL10n
import MEGAPresentation
import MEGAUIKit
import Search
import SwiftUI

extension SearchConfig {
    static func searchConfig(
        contextPreviewFactory: ContextPreviewFactory,
        defaultEmptyViewAsset: @escaping () -> EmptyViewAssets
    ) -> SearchConfig {
        .init(
            chipAssets: .init(
                selectionIndicatorImage: UIImage.turquoiseCheckmark,
                closeIcon: UIImage.miniplayerClose,
                selectedForeground: TokenColors.Text.colorInverse.swiftUI,
                selectedBackground: TokenColors.Components.selectionControl.swiftUI,
                normalForeground: TokenColors.Text.primary.swiftUI,
                normalBackground: TokenColors.Button.secondary.swiftUI
            ),
            emptyViewAssetFactory: { chip, query in
                let titleTextColor: (ColorScheme) -> Color = { colorScheme in
                    guard DIContainer.featureFlagProvider.isFeatureFlagEnabled(for: .designToken) else {
                        return colorScheme == .light ? UIColor.gray515151.swiftUI : UIColor.grayD1D1D1.swiftUI
                    }

                    return TokenColors.Icon.secondary.swiftUI
                }

                guard let chip else {
                    guard !query.isSearchActive else {
                        return .init(
                            image: Image(.searchEmptyState),
                            title: Strings.Localizable.Home.Search.Empty.noChipSelected, 
                            titleTextColor: titleTextColor
                        )
                    }

                    return defaultEmptyViewAsset()
                }

                switch chip.id {
                case SearchChipEntity.docs.id:
                    return .init(
                        image: Image(.noResultsDocuments),
                        title: Strings.Localizable.Home.Search.Empty.noDocuments,
                        titleTextColor: titleTextColor
                    )
                case SearchChipEntity.audio.id:
                    return .init(
                        image: Image(.noResultsAudio),
                        title: Strings.Localizable.Home.Search.Empty.noAudio,
                        titleTextColor: titleTextColor
                    )
                case SearchChipEntity.video.id:
                    return .init(
                        image: Image(.noResultsVideo),
                        title: Strings.Localizable.Home.Search.Empty.noVideos,
                        titleTextColor: titleTextColor
                    )
                case SearchChipEntity.images.id:
                    return .init(
                        image: Image(.noResultsImages),
                        title: Strings.Localizable.Home.Search.Empty.noImages,
                        titleTextColor: titleTextColor
                    )
                case SearchChipEntity.folders.id:
                    return .init(
                        image: Image(.noResultsFolders),
                        title: Strings.Localizable.Home.Search.Empty.noFolders,
                        titleTextColor: titleTextColor
                    )
                case SearchChipEntity.pdf.id:
                    return .init(
                        image: Image(.noResultsDocuments),
                        title: Strings.Localizable.Home.Search.Empty.noPdfs,
                        titleTextColor: titleTextColor
                    )
                case SearchChipEntity.presentation.id:
                    return .init(
                        image: Image(.noResultsPresentations),
                        title: Strings.Localizable.Home.Search.Empty.noPresentations,
                        titleTextColor: titleTextColor
                    )
                case SearchChipEntity.archives.id:
                    return .init(
                        image: Image(.noResultsArchives),
                        title: Strings.Localizable.Home.Search.Empty.noArchives,
                        titleTextColor: titleTextColor
                    )
                default:
                    return defaultEmptyViewAsset()
                }
            },
            rowAssets: .init(
                contextImage: UIImage.moreList.withTintColorAsOriginal(TokenColors.Icon.secondary),
                itemSelected: UIImage.checkBoxSelected,
                itemUnselected: UIImage.checkBoxUnselected,
                playImage: UIImage.videoList,
                downloadedImage: UIImage.downloaded,
                moreList: UIImage.moreList.withTintColorAsOriginal(TokenColors.Icon.secondary),
                moreGrid: UIImage.moreGrid.withTintColorAsOriginal(TokenColors.Icon.secondary)
            ),
            colorAssets: .init(
                F7F7F7: UIColor.whiteF7F7F7.swiftUI,
                _161616: UIColor.black161616.swiftUI,
                _545458: UIColor.gray545458.swiftUI,
                CE0A11: UIColor.redCE0A11.swiftUI,
                F30C14: UIColor.redF30C14.swiftUI,
                F95C61: UIColor.redF95C61.swiftUI,
                F7363D: UIColor.redF7363D.swiftUI,
                _1C1C1E: UIColor.black1C1C1E.swiftUI,
                _00A886: UIColor.green00A886.swiftUI,
                _3C3C43: UIColor.gray3C3C43.swiftUI,
                checkmarkBackgroundTintColor: UIColor.isDesignTokenEnabled()
                ? TokenColors.Support.success.swiftUI
                : UIColor.turquoise.swiftUI
            ),
            contextPreviewFactory: contextPreviewFactory
        )
    }
}
