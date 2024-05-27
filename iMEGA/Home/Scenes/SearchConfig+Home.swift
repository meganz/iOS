import MEGADesignToken
import MEGAL10n
import MEGAPresentation
import MEGAUIKit
import Search
import SwiftUI

// Colors catering for backward-compatibility with non-semantic color system
extension UIColor {
    /// Border of cells in thumbnail mode
    static let cloudDriveThumbnailModeBorder = UIColor(
        dynamicProvider: {
            $0.userInterfaceStyle == .light
            ? UIColor(red: 0.969, green: 0.969, blue: 0.9690, alpha: 1)
            : UIColor(red: 0.329, green: 0.329, blue: 0.329, alpha: 1)
        }
    )
    
    /// Color for vibrancy
    static let cloudDriveVibrance = UIColor(
        dynamicProvider: {
            $0.userInterfaceStyle == .light
            ? UIColor(red: 0.953, green: 0.047, blue: 0.078, alpha: 1)
            : UIColor(red: 0.969, green: 0.212, blue: 0.239, alpha: 1)
        }
    )
    
    /// Color for property icons
    static let cloudDrivePropertyIcon = UIColor(
        dynamicProvider: {
            $0.userInterfaceStyle == .light
            ? UIColor(red: 0.518, green: 0.518, blue: 0.518, alpha: 1)
            : UIColor(red: 0.710, green: 0.710, blue: 0.710, alpha: 1)
        }
    )
}

extension SearchConfig {
    static func searchConfig(
        contextPreviewFactory: ContextPreviewFactory,
        defaultEmptyViewAsset: @escaping () -> EmptyViewAssets
    ) -> SearchConfig {
        let isDesignTokenEnabled = UIColor.isDesignTokenEnabled()
        return .init(
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
                    guard isDesignTokenEnabled else {
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
                itemSelected: isDesignTokenEnabled ? UIImage.checkBoxSelectedSemantic : UIImage.checkBoxSelected,
                itemUnselected: UIImage.checkBoxUnselected,
                playImage: UIImage.videoList,
                downloadedImage: UIImage.downloaded,
                moreList: isDesignTokenEnabled ? UIImage.moreList.withTintColorAsOriginal(TokenColors.Icon.secondary) : UIImage.moreList.withRenderingMode(.alwaysOriginal),
                moreGrid: UIImage.moreGrid.withTintColorAsOriginal(TokenColors.Icon.secondary)
            ),
            colorAssets: .init(
                unselectedBorderColor: isDesignTokenEnabled ? TokenColors.Border.strong.swiftUI : UIColor.cloudDriveThumbnailModeBorder.swiftUI,
                selectedBorderColor: isDesignTokenEnabled ? TokenColors.Support.success.swiftUI : UIColor.turquoise.swiftUI,
                titleTextColor: UIColor.primaryTextColor().swiftUI,
                subtitleTextColor: UIColor.secondaryTextColor().swiftUI,
                vibrantColor: isDesignTokenEnabled ? TokenColors.Text.error.swiftUI : UIColor.cloudDriveVibrance.swiftUI, 
                resultPropertyColor: isDesignTokenEnabled ? TokenColors.Icon.secondary.swiftUI : UIColor.cloudDrivePropertyIcon.swiftUI,
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
                checkmarkBackgroundTintColor: isDesignTokenEnabled ? TokenColors.Background.page.swiftUI : UIColor.turquoise.swiftUI
            ),
            contextPreviewFactory: contextPreviewFactory
        )
    }
}
