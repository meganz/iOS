import MEGAAssets
import MEGADesignToken
import Search
import SwiftUI
import UIKit

extension SearchConfig {
    /// `SearchConfig` for the new Transfers screen. The `rowBuilder` closure is
    /// the load-bearing piece: it resolves the per-row VM from the registry by
    /// `ResultId` and constructs `TransferResultRowView`. Non-transfer results
    /// return `nil`, preserving the default node row path for any future
    /// heterogeneous use.
    ///
    /// `chipAssets`, `rowAssets`, and `colorAssets` mirror `SearchConfig.favourites`
    /// for visual parity with other Search-backed screens. Most fields are unused
    /// here because the custom `rowBuilder` and `emptyViewAssetFactory` override
    /// the default node row path, but `SearchConfig.init` still requires them.
    @MainActor
    static func transfers(registry: TransferRegistry) -> SearchConfig {
        var config = SearchConfig(
            chipAssets: .init(
                selectionIndicatorImage: MEGAAssets.UIImage.turquoiseCheckmark,
                closeIcon: MEGAAssets.UIImage.miniplayerClose,
                selectedForeground: TokenColors.Text.inverse.swiftUI,
                selectedBackground: TokenColors.Components.selectionControl.swiftUI,
                normalForeground: TokenColors.Text.primary.swiftUI,
                normalBackground: TokenColors.Button.secondary.swiftUI
            ),
            emptyViewAssetFactory: { _, _ in
                SearchConfig.EmptyViewAssets(
                    image: Image(systemName: "tray"),
                    title: "",
                    titleTextColor: TokenColors.Icon.secondary.swiftUI,
                    actions: []
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
            )
        )
        config.rowBuilder = { result in
            guard result.type == .transfer else { return nil }
            guard let vm = registry.rowViewModel(for: result.id) else {
                return AnyView(EmptyView())
            }
            return AnyView(
                TransferResultRowView(viewModel: vm)
                    .listRowInsets(EdgeInsets())
            )
        }
        return config
    }
}
