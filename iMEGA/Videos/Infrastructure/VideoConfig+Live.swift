import MEGADesignToken
import SwiftUI
import Video

extension VideoConfig {
    
    static func live() -> VideoConfig { VideoConfig(
        videoListAssets: VideoConfig.VideoListAssets(
            noResultVideoImage: UIImage.noResultsVideoV2,
            checkmarkImage: UIImage.turquoiseCheckmark,
            chipDownArrowImage: UIImage.filterChipDownArrow
        ),
        rowAssets: VideoConfig.RowAssets(
            favoriteImage: UIImage.favouriteThumbnail,
            playImage: UIImage.blackPlayButton,
            publicLinkImage: UIImage.linked,
            moreImage: UIImage.moreList,
            addPlaylistImage: UIImage.navigationbarAdd,
            rectangleVideoStackPlaylistImage: UIImage.rectangleVideoStack,
            favouritePlaylistThumbnailImage: UIImage.favouritePlaylistThumbnail,
            labelAssets: VideoConfig.RowAssets.LabelAssets(
                redImage: UIImage.redSmall,
                orangeImage: UIImage.orangeSmall,
                yellowImage: UIImage.yellowSmall,
                greenImage: UIImage.greenSmall,
                blueImage: UIImage.blueSmall,
                purpleImage: UIImage.purpleSmall,
                greyImage: UIImage.greySmall
            )
        ),
        colorAssets: VideoConfig.ColorAssets(
            primaryTextColor: TokenColors.Text.primary.swiftUI,
            secondaryTextColor: TokenColors.Text.secondary.swiftUI,
            primaryIconColor: TokenColors.Icon.primary.swiftUI,
            secondaryIconColor: TokenColors.Icon.secondary.swiftUI,
            pageBackgroundColor: TokenColors.Background.page.swiftUI,
            whiteColor: TokenColors.Text.onColor.swiftUI,
            durationTextColor: TokenColors.Text.primary.swiftUI,
            tabActiveIndicatorColor: TokenColors.Button.brand.swiftUI,
            tabInactiveIndicatorColor: TokenColors.Background.surface1.swiftUI,
            tabInactiveTextColor: TokenColors.Text.primary.swiftUI,
            addPlaylistButtonTextColor: TokenColors.Text.inverseAccent.swiftUI,
            addPlaylistButtonBackgroundColor: TokenColors.Icon.accent.swiftUI,
            toolbarBackgroundColor: TokenColors.Background.surface1.swiftUI,
            navigationBgColor: TokenColors.Background.surface1.swiftUI,
            emptyFavoriteThumbnailBackgroundColor: TokenColors.Background.surface3.swiftUI,
            emptyFavoriteThumbnaillImageForegroundColor: TokenColors.Icon.secondary.swiftUI,
            videoThumbnailImageViewPlaceholderBackgroundColor: MEGAAppColor.Videos.videoThumbnailImageViewPlaceholderBackgroundColor.color,
            videoThumbnailDurationTextBackgroundColor: MEGAAppColor.Videos.videoThumbnailDurationTextBackgroundColor.color,
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
        toolbarAssets: VideoConfig.ToolbarAssets(
            offlineImage: UIImage.offline,
            linkImage: UIImage.link,
            saveToPhotosImage: UIImage.saveToPhotos,
            sendToChatImage: UIImage.sendToChat,
            moreListImage: UIImage.moreList
        ),
        recentlyWatchedAssets: RecentlyWatchedAssets(
            emptyView: .init(
                color: .init(
                    pageBackgroundColor: TokenColors.Background.page.swiftUI,
                    textColor: TokenColors.Text.primary.swiftUI,
                    iconColor: TokenColors.Icon.secondary.swiftUI
                ),
                recentsEmptyStateImage: UIImage.recentlyWatchedVideosEmptyState
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
                    publicLinkImage: UIImage.linked,
                    addButtonImage: UIImage(systemName: "plus")!,
                    playButtonImage: UIImage(systemName: "play.fill")!
                ),
                color: .init(
                    pageBackgroundColor: TokenColors.Background.surface1.swiftUI,
                    thumbnailBackgroundColor: TokenColors.Background.surface2.swiftUI,
                    primaryTextColor: TokenColors.Text.primary.swiftUI,
                    secondaryTextColor: TokenColors.Text.secondary.swiftUI,
                    secondaryIconColor: TokenColors.Icon.secondary.swiftUI,
                    buttonTintColor: TokenColors.Icon.accent.swiftUI
                )
            ),
            favouritesEmptyStateImage: UIImage.favouritesEmptyState,
            noResultVideoPlaylistImage: UIImage.rectangleVideoStackOutline,
            videoPlaylistThumbnailFallbackImage: UIImage.videoPlaylistThumbnailFallback
        )
    )}
}
