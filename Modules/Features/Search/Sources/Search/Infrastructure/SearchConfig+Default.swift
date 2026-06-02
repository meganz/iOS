import MEGAAssets
import MEGADesignToken
import MEGAUIKit
import SwiftUI

// Shared MEGA-branded asset bundles for `SearchConfig`. `chipAssets`, `rowAssets`,
// and `colorAssets` are identical across every consumer (Favourites, Home, FolderLink,
// Recents, Transfers), so they default to these via `SearchConfig.init`. Callers supply
// only what actually varies per screen: the `emptyViewAssetFactory`, and optionally a
// `rowBuilder` for non-node result types.

public extension SearchConfig.ChipAssets {
    static var `default`: SearchConfig.ChipAssets {
        .init(
            selectionIndicatorImage: MEGAAssets.UIImage.turquoiseCheckmark,
            closeIcon: MEGAAssets.UIImage.miniplayerClose,
            selectedForeground: TokenColors.Text.inverse.swiftUI,
            selectedBackground: TokenColors.Components.selectionControl.swiftUI,
            normalForeground: TokenColors.Text.primary.swiftUI,
            normalBackground: TokenColors.Button.secondary.swiftUI
        )
    }
}

public extension SearchConfig.RowAssets {
    static var `default`: SearchConfig.RowAssets {
        .init(
            contextImage: MEGAAssets.UIImage.moreList.withTintColorAsOriginal(TokenColors.Icon.secondary),
            itemSelected: MEGAAssets.UIImage.checkBoxSelectedSemantic,
            itemUnselected: MEGAAssets.UIImage.checkBoxUnselected.withTintColorAsOriginal(TokenColors.Border.strong),
            playImage: MEGAAssets.UIImage.videoList,
            downloadedImage: MEGAAssets.UIImage.downloaded,
            moreList: MEGAAssets.UIImage.moreList.withTintColorAsOriginal(TokenColors.Icon.secondary),
            moreGrid: MEGAAssets.UIImage.moreHorizontal
        )
    }
}

public extension SearchConfig.ColorAssets {
    static var `default`: SearchConfig.ColorAssets {
        .init(
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
    }
}
