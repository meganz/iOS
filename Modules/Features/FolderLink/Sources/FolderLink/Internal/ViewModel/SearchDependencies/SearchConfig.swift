import MEGAAssets
import MEGADesignToken
import MEGAL10n
import Search
import SwiftUI

extension SearchConfig {
    static func folderLink(_ isCloudDriveRevampEnabled: Bool) -> SearchConfig {
        let contextPreviewFactory = SearchConfig.ContextPreviewFactory { _ in
            .init(actions: [], previewMode: .noPreview) // todo handle contextPreview
        }
        
        let emptyViewAssets = SearchConfig.EmptyViewAssets(
            image: MEGAAssets.Image.glassFolder,
            title: Strings.Localizable.emptyFolder,
            titleTextColor: TokenColors.Text.primary.swiftUI
        )
        
        return SearchConfig.searchConfig(
            isCloudDriveRevampEnabled: isCloudDriveRevampEnabled,
            contextPreviewFactory: contextPreviewFactory,
            defaultEmptyViewAsset: { emptyViewAssets }
        )
    }
    
    /// Folder Link currently only cares about context preview and empty assets
    /// The rest of config are either not supported or same as CloudDrive, so they are copied over from CloudDriveViewControllerFactory
    private static func searchConfig(
        isCloudDriveRevampEnabled: Bool,
        contextPreviewFactory: ContextPreviewFactory,
        defaultEmptyViewAsset: @escaping () -> EmptyViewAssets
    ) -> SearchConfig {
        .init(
            chipAssets: .init(
                selectionIndicatorImage: MEGAAssets.UIImage.turquoiseCheckmark,
                closeIcon: MEGAAssets.UIImage.miniplayerClose,
                selectedForeground: TokenColors.Text.inverse.swiftUI,
                selectedBackground: TokenColors.Components.selectionControl.swiftUI,
                normalForeground: TokenColors.Text.primary.swiftUI,
                normalBackground: TokenColors.Button.secondary.swiftUI
            ),
            emptyViewAssetFactory: { _, _ in
                defaultEmptyViewAsset()
            },
            rowAssets: .init(
                contextImage: MEGAAssets.UIImage.moreList.withTintColorAsOriginal(TokenColors.Icon.secondary),
                itemSelected: MEGAAssets.UIImage.checkBoxSelectedSemantic,
                itemUnselected: MEGAAssets.UIImage.checkBoxUnselected.withTintColorAsOriginal(TokenColors.Border.strong),
                playImage: MEGAAssets.UIImage.videoList,
                downloadedImage: MEGAAssets.UIImage.downloaded,
                moreList: MEGAAssets.UIImage.moreList.withTintColorAsOriginal(TokenColors.Icon.secondary),
                moreGrid: isCloudDriveRevampEnabled
                ? MEGAAssets.UIImage.moreHorizontal
                : MEGAAssets.UIImage.moreGrid.withTintColorAsOriginal(TokenColors.Icon.secondary)
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
                verticalThumbnailFooterText: isCloudDriveRevampEnabled ? TokenColors.Icon.onColor.swiftUI: TokenColors.Text.primary.swiftUI,
                verticalThumbnailFooterBackground: isCloudDriveRevampEnabled ? TokenColors.Background.surfaceTransparent.swiftUI :  TokenColors.Background.surface1.swiftUI,
                verticalThumbnailPreviewBackground: TokenColors.Background.surface1.swiftUI,
                verticalThumbnailTopIconsBackground: TokenColors.Background.surface2.swiftUI,
                listRowSeparator: TokenColors.Border.strong.swiftUI,
                checkmarkBackgroundTintColor: TokenColors.Support.success.swiftUI,
                listHeaderTextColor: TokenColors.Text.secondary.swiftUI,
                listHeaderBackgroundColor: TokenColors.Background.page.swiftUI
            ),
            contextPreviewFactory: contextPreviewFactory
        )
    }
}
