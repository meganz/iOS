import MEGADesignToken
import MEGAAssets
import MEGASwiftUI
import SwiftUI

extension VideoConfig {
    
    /// Internal Video SPM module Dependencies helper for SwiftUI
    static let preview = VideoConfig(
        videoListAssets: VideoListAssets(
            noResultVideoImage: MEGAAssetsPreviewImageProvider.image(named: "noResultsVideo")!
        ),
        rowAssets: RowAssets(
            favoriteImage: MEGAAssetsPreviewImageProvider.image(named: "favouriteThumbnail")!,
            playImage: MEGAAssetsPreviewImageProvider.image(named: "blackPlayButton")!,
            publicLinkImage: MEGAAssetsPreviewImageProvider.image(named: "linked")!,
            moreImage: MEGAAssetsPreviewImageProvider.image(named: "moreList")!,
            addPlaylistImage: MEGAAssetsPreviewImageProvider.image(named: "navigationbar_add")!,
            rectangleVideoStackPlaylistImage: MEGAAssetsPreviewImageProvider.image(named: "rectangleVideoStack")!,
            favouritePlaylistThumbnailImage: MEGAAssetsPreviewImageProvider.image(named: "FavouritePlaylistThumbnail")!,
            labelAssets: VideoConfig.RowAssets.LabelAssets(
                redImage: MEGAAssetsPreviewImageProvider.image(named: "RedSmall")!,
                orangeImage: MEGAAssetsPreviewImageProvider.image(named: "OrangeSmall")!,
                yellowImage: MEGAAssetsPreviewImageProvider.image(named: "YellowSmall")!,
                greenImage: MEGAAssetsPreviewImageProvider.image(named: "GreenSmall")!,
                blueImage: MEGAAssetsPreviewImageProvider.image(named: "BlueSmall")!,
                purpleImage: MEGAAssetsPreviewImageProvider.image(named: "PurpleSmall")!,
                greyImage: MEGAAssetsPreviewImageProvider.image(named: "GreySmall")!
            )
        ),
        colorAssets: ColorAssets(
            primaryTextColor: .primary,
            secondaryTextColor: .secondary,
            secondaryIconColor: .secondary,
            pageBackgroundColor: .clear,
            whiteColor: .white,
            durationTextColor: Color(uiColor: MEGAAssetsPreviewColorProvider.color(named: "black_161616")!).opacity(0.5),
            tabActiveIndicatorColor: Color(uiColor: MEGAAssetsPreviewColorProvider.color(named: "red_F30C14")!),
            tabInactiveIndicatorColor: Color.clear,
            tabInactiveTextColor: Color(uiColor: MEGAAssetsPreviewColorProvider.color(named: "gray_515151")!),
            addPlaylistButtonBackgroundColor: Color(uiColor: MEGAAssetsPreviewColorProvider.color(named: "videoPlaylist_addButtonBackground")!),
            toolbarBackgroundColor: Color(uiColor: MEGAAssetsPreviewColorProvider.color(named: "navigationBgColor")!),
            navigationBgColor: Color(uiColor: MEGAAssetsPreviewColorProvider.color(named: "navigationBgColor")!),
            emptyFavoriteThumbnailLightBackgroundColor: Color(uiColor: MEGAAssetsPreviewColorProvider.color(named: "gray_E2E2E2")!),
            emptyFavoriteThumbnailDarkBackgroundColor: Color(uiColor: MEGAAssetsPreviewColorProvider.color(named: "black_2c2c2e")!),
            emptyFavoriteThumbnaillImageLightForegroundColor: Color(uiColor: MEGAAssetsPreviewColorProvider.color(named: "gray_BBBBBB")!),
            emptyFavoriteThumbnaillImageDarkForegroundColor: Color(uiColor: MEGAAssetsPreviewColorProvider.color(named: "gray_D1D1D1")!),
            videoCellSecondaryLightTextColor: Color(uiColor: MEGAAssetsPreviewColorProvider.color(named: "gray_BBBBBB")!),
            videoCellSecondaryDarkTextColor: Color(uiColor: MEGAAssetsPreviewColorProvider.color(named: "gray_D1D1D1")!),
            videoThumbnailImageViewPlaceholderBackgroundColor: Color.black,
            videoThumbnailDurationTextBackgroundColor: Color.black.opacity(0.2)
        ),
        toolbarAssets: ToolbarAssets(
            offlineImage: MEGAAssetsPreviewImageProvider.image(named: "offline")!,
            linkImage: MEGAAssetsPreviewImageProvider.image(named: "link")!,
            saveToPhotosImage: MEGAAssetsPreviewImageProvider.image(named: "saveToPhotos")!,
            hudMinusImage: MEGAAssetsPreviewImageProvider.image(named: "hudMinus")!,
            moreListImage: MEGAAssetsPreviewImageProvider.image(named: "moreList")!
        ),
        recentlyWatchedAssets: RecentlyWatchedAssets(
            emptyView: .init(
                color: .init(
                    pageBackgroundColor: TokenColors.Background.page.swiftUI,
                    textColor: TokenColors.Text.primary.swiftUI,
                    iconColor: TokenColors.Icon.secondary.swiftUI
                )
            ),
            listView: .init(
                header: .init(
                    color: .init(
                        primaryTextColor: TokenColors.Text.primary.swiftUI,
                        pageBackgroundColor: TokenColors.Background.page.swiftUI
                    )
                ),
                cell: .init(
                    color: .init(
                        primaryTextColor: TokenColors.Text.primary.swiftUI,
                        secondaryTextColor: TokenColors.Text.secondary.swiftUI,
                        secondaryIconColor: TokenColors.Icon.secondary.swiftUI,
                        durationTextColor: TokenColors.Button.primary.swiftUI,
                        durationTextBackgroundColor: TokenColors.Background.blur.swiftUI,
                        pageBackgroundColor: TokenColors.Background.page.swiftUI,
                        progressBarActiveColor: TokenColors.Button.brand.swiftUI,
                        progressBarBackgroundColor: TokenColors.Button.brand.swiftUI
                    )
                )
            )
        )
    )
}
