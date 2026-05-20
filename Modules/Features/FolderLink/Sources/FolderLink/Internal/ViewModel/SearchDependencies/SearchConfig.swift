import MEGAAssets
import MEGADesignToken
import MEGAL10n
import Search
import SwiftUI

extension SearchConfig {
    /// Folder Link currently only cares about empty assets.
    /// The rest of config are either not supported or same as CloudDrive, so they are copied over from CloudDriveViewControllerFactory
    static var folderLink: SearchConfig {
        let emptyViewAssets = SearchConfig.EmptyViewAssets(
            image: MEGAAssets.Image.glassFolder,
            title: Strings.Localizable.emptyFolder,
            titleTextColor: TokenColors.Text.primary.swiftUI
        )

        return .init(
            chipAssets: .init(
                selectionIndicatorImage: MEGAAssets.UIImage.turquoiseCheckmark,
                closeIcon: MEGAAssets.UIImage.miniplayerClose,
                selectedForeground: TokenColors.Text.inverse.swiftUI,
                selectedBackground: TokenColors.Components.selectionControl.swiftUI,
                normalForeground: TokenColors.Text.primary.swiftUI,
                normalBackground: TokenColors.Button.secondary.swiftUI
            ),
            emptyViewAssetFactory: { _, _ in emptyViewAssets },
            rowAssets: .init(
                contextImage: MEGAAssets.UIImage.moreList.withTintColorAsOriginal(TokenColors.Icon.secondary),
                itemSelected: MEGAAssets.UIImage.checkBoxSelectedSemantic,
                itemUnselected: MEGAAssets.UIImage.checkBoxUnselected.withTintColorAsOriginal(TokenColors.Border.strong),
                playImage: MEGAAssets.UIImage.videoList,
                downloadedImage: MEGAAssets.UIImage.downloaded,
                moreList: MEGAAssets.UIImage.moreList.withTintColorAsOriginal(TokenColors.Icon.secondary),
                moreGrid: MEGAAssets.UIImage.moreHorizontal
            ),
            colorAssets: .init(
                unselectedBorderColor: TokenColors.Border.strong.swiftUI,
                selectedBorderColor: TokenColors.Support.success.swiftUI,
                titleTextColor: TokenColors.Text.primary.swiftUI,
                subtitleTextColor: TokenColors.Text.secondary.swiftUI,
                nodeDescriptionTextNormalColor: TokenColors.Text.secondary.swiftUI,
                tagsTextColor: TokenColors.Text.primary.swiftUI,
                textHighlightColor: TokenColors.Notifications.notificationSuccess.swiftUI,
                vibrantColor: TokenColors.Text.error.swiftUI,
                verticalThumbnailFooterText: TokenColors.Icon.onColor.swiftUI,
                verticalThumbnailFooterBackground: TokenColors.Background.surfaceTransparent.swiftUI,
                verticalThumbnailPreviewBackground: TokenColors.Background.surface1.swiftUI,
                verticalThumbnailTopIconsBackground: TokenColors.Background.surface2.swiftUI,
                listRowSeparator: TokenColors.Border.strong.swiftUI,
                checkmarkBackgroundTintColor: TokenColors.Support.success.swiftUI,
                listHeaderTextColor: TokenColors.Text.secondary.swiftUI,
                listHeaderBackgroundColor: TokenColors.Background.page.swiftUI
            )
        )
    }
}
