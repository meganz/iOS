import MEGAAppPresentation
import MEGAAssets
import MEGADesignToken
import MEGAL10n
import MEGAUIKit
import Search
import SwiftUI

extension SearchConfig {
    static var homeSearchConfig: SearchConfig {
        .init(
            chipAssets: .init(
                selectionIndicatorImage: MEGAAssets.UIImage.turquoiseCheckmark,
                closeIcon: MEGAAssets.UIImage.miniplayerClose,
                selectedForeground: TokenColors.Text.inverse.swiftUI,
                selectedBackground: TokenColors.Components.selectionControl.swiftUI,
                normalForeground: TokenColors.Text.primary.swiftUI,
                normalBackground: TokenColors.Button.secondary.swiftUI
            ),
            emptyViewAssetFactory: { _, _ in // This isn't used in Revamp UI, this is just here to satisfy the struct's initialization
                    .init(
                        image: MEGAAssets.Image.glassSearch02,
                        title: Strings.Localizable.Home.Search.Empty.noChipSelected,
                        titleTextColor: TokenColors.Icon.secondary.swiftUI
                    )
            },
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
            ),
            contextPreviewFactory: .init( // This isn't used in Revamp UI, this is just here to satisfy the struct's initialization
                previewContentForResult: { _ in .init(actions: [], previewMode: .noPreview) }
            )
        )
    }
}
