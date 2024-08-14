import MEGAAssets
import MEGADesignToken
import MEGASwiftUI
import SwiftUI

extension VideoConfig {
    
    /// Internal Video SPM module Dependencies helper for SwiftUI
    static let preview = VideoConfig(
        videoListAssets: VideoListAssets(
            noResultVideoImage: MEGAAssetsImageProvider.image(named: "noResultsVideo")!,
            checkmarkImage: MEGAAssetsImageProvider.image(named: "turquoise_checkmark")!,
            chipDownArrowImage: MEGAAssetsImageProvider.image(named: "filterChipDownArrow")!
        ),
        rowAssets: RowAssets(
            favoriteImage: MEGAAssetsImageProvider.image(named: "favouriteThumbnail")!,
            playImage: MEGAAssetsImageProvider.image(named: "blackPlayButton")!,
            publicLinkImage: MEGAAssetsImageProvider.image(named: "linked")!,
            moreImage: MEGAAssetsImageProvider.image(named: "moreList")!,
            addPlaylistImage: MEGAAssetsImageProvider.image(named: "navigationbar_add")!,
            rectangleVideoStackPlaylistImage: MEGAAssetsImageProvider.image(named: "rectangleVideoStack")!,
            favouritePlaylistThumbnailImage: MEGAAssetsImageProvider.image(named: "FavouritePlaylistThumbnail")!,
            labelAssets: VideoConfig.RowAssets.LabelAssets(
                redImage: MEGAAssetsImageProvider.image(named: "RedSmall")!,
                orangeImage: MEGAAssetsImageProvider.image(named: "OrangeSmall")!,
                yellowImage: MEGAAssetsImageProvider.image(named: "YellowSmall")!,
                greenImage: MEGAAssetsImageProvider.image(named: "GreenSmall")!,
                blueImage: MEGAAssetsImageProvider.image(named: "BlueSmall")!,
                purpleImage: MEGAAssetsImageProvider.image(named: "PurpleSmall")!,
                greyImage: MEGAAssetsImageProvider.image(named: "GreySmall")!
            )
        ),
        colorAssets: ColorAssets(
            primaryTextColor: TokenColors.Text.primary.swiftUI,
            secondaryTextColor: TokenColors.Text.secondary.swiftUI,
            primaryIconColor: TokenColors.Icon.primary.swiftUI,
            secondaryIconColor: TokenColors.Icon.secondary.swiftUI,
            pageBackgroundColor: TokenColors.Background.page.swiftUI,
            whiteColor: TokenColors.Text.onColor.swiftUI,
            durationTextColor: Color(uiColor: MEGAAssetsColorProvider.color(named: "black_161616")!).opacity(0.5),
            tabActiveIndicatorColor: Color(uiColor: MEGAAssetsColorProvider.color(named: "red_F30C14")!),
            tabInactiveIndicatorColor: Color.clear,
            tabInactiveTextColor: Color(uiColor: MEGAAssetsColorProvider.color(named: "gray_515151")!),
            addPlaylistButtonTextColor: TokenColors.Text.inverseAccent.swiftUI,
            addPlaylistButtonBackgroundColor: TokenColors.Icon.accent.swiftUI,
            toolbarBackgroundColor: Color(uiColor: MEGAAssetsColorProvider.color(named: "navigationBgColor")!),
            navigationBgColor: Color(uiColor: MEGAAssetsColorProvider.color(named: "navigationBgColor")!),
            emptyFavoriteThumbnailBackgroundColor: TokenColors.Background.surface2.swiftUI,
            emptyFavoriteThumbnaillImageForegroundColor: TokenColors.Icon.secondary.swiftUI,
            videoThumbnailImageViewPlaceholderBackgroundColor: Color.black,
            videoThumbnailDurationTextBackgroundColor: Color.black.opacity(0.2),
            disabledColor: TokenColors.Text.disabled.swiftUI,
            checkmarkColor: TokenColors.Support.success.swiftUI,
            bottomSheetBackgroundColor: TokenColors.Background.surface1.swiftUI, 
            bottomSheetHeaderBackgroundColor: TokenColors.Background.surface1.swiftUI,
            bottomSheetCellSelectedBackgroundColor: TokenColors.Background.surface1.swiftUI,
            videoFilterChipActiveForegroundColor: TokenColors.Text.inverseAccent.swiftUI,
            videoFilterChipInactiveForegroundColor: TokenColors.Text.primary.swiftUI,
            videoFilterChipActiveBackgroundColor: TokenColors.Button.primary.swiftUI,
            videoFilterChipInactiveBackgroundColor: TokenColors.Background.surface2.swiftUI
            
        ),
        toolbarAssets: ToolbarAssets(
            offlineImage: MEGAAssetsImageProvider.image(named: "offline")!,
            linkImage: MEGAAssetsImageProvider.image(named: "link")!,
            saveToPhotosImage: MEGAAssetsImageProvider.image(named: "saveToPhotos")!,
            sendToChatImage: MEGAAssetsImageProvider.image(named: "sendToChat")!,
            moreListImage: MEGAAssetsImageProvider.image(named: "moreList")!
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
        ),
        playlistContentAssets: PlaylistContentAssets(
            headerView: .init(
                image: .init(
                    dotSeparatorImage: UIImage(systemName: "circle.fill")!,
                    publicLinkImage: MEGAAssetsImageProvider.image(named: "linked")!,
                    addButtonImage: UIImage(systemName: "plus")!,
                    playButtonImage: UIImage(systemName: "play.fill")!
                ),
                color: .init(
                    pageBackgroundColor: TokenColors.Background.surface1.swiftUI,
                    thumbnailBackgroundColor: TokenColors.Background.surface2.swiftUI,
                    primaryTextColor: TokenColors.Text.primary.swiftUI,
                    secondaryTextColor: TokenColors.Text.secondary.swiftUI,
                    secondaryIconColor: TokenColors.Text.secondary.swiftUI,
                    buttonTintColor: MEGAAssetsColorProvider.swiftUIColor(named: "videoPlaylistContent_buttonTintColor")
                )
            ),
            favouritesEmptyStateImage: MEGAAssetsImageProvider.image(named: "favouritesEmptyState")!,
            noResultVideoPlaylistImage: MEGAAssetsImageProvider.image(named: "rectangleVideoStackOutline")!
        )
    )
}
