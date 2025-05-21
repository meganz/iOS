import MEGAAssets
import MEGADesignToken
import SwiftUI
import Video

extension VideoConfig {
    
    static func live() -> VideoConfig { VideoConfig(
        videoListAssets: VideoConfig.VideoListAssets(
            noResultVideoImage: MEGAAssets.UIImage.noResultsVideoV2,
            checkmarkImage: MEGAAssets.UIImage.turquoiseCheckmark,
            chipDownArrowImage: MEGAAssets.UIImage.filterChipDownArrow
        ),
        rowAssets: VideoConfig.RowAssets(
            favoriteImage: MEGAAssets.UIImage.favouriteThumbnail,
            playImage: MEGAAssets.UIImage.blackPlayButton,
            publicLinkImage: MEGAAssets.UIImage.linked,
            moreImage: MEGAAssets.UIImage.moreList,
            addPlaylistImage: MEGAAssets.UIImage.navigationbarAdd,
            rectangleVideoStackPlaylistImage: MEGAAssets.UIImage.rectangleVideoStack,
            favouritePlaylistThumbnailImage: MEGAAssets.UIImage.favouritePlaylistThumbnail,
            grabberIconImage: MEGAAssets.UIImage.grabberIcon,
            downloadedImage: MEGAAssets.UIImage.downloaded,
            labelAssets: VideoConfig.RowAssets.LabelAssets(
                redImage: MEGAAssets.UIImage.redSmall,
                orangeImage: MEGAAssets.UIImage.orangeSmall,
                yellowImage: MEGAAssets.UIImage.yellowSmall,
                greenImage: MEGAAssets.UIImage.greenSmall,
                blueImage: MEGAAssets.UIImage.blueSmall,
                purpleImage: MEGAAssets.UIImage.purpleSmall,
                greyImage: MEGAAssets.UIImage.greySmall
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
            videoThumbnailImageViewPlaceholderBackgroundColor: UIColor.black.swiftUI,
            videoThumbnailDurationTextBackgroundColor: TokenColors.Background.surface1.swiftUI,
            disabledColor: TokenColors.Text.disabled.swiftUI,
            checkmarkColor: TokenColors.Support.success.swiftUI,
            bottomSheetBackgroundColor: TokenColors.Background.surface1.swiftUI,
            bottomSheetHeaderBackgroundColor: TokenColors.Background.surface1.swiftUI,
            bottomSheetCellSelectedBackgroundColor: TokenColors.Background.surface1.swiftUI,
            videoFilterChipActiveForegroundColor: TokenColors.Text.inverseAccent.swiftUI,
            videoFilterChipInactiveForegroundColor: TokenColors.Text.primary.swiftUI,
            videoFilterChipActiveBackgroundColor: TokenColors.Button.primary.swiftUI,
            videoFilterChipInactiveBackgroundColor: TokenColors.Background.surface2.swiftUI,
            highlightedTextColor: TokenColors.Notifications.notificationSuccess.swiftUI
        ),
        toolbarAssets: VideoConfig.ToolbarAssets(
            offlineImage: MEGAAssets.UIImage.offline,
            linkImage: MEGAAssets.UIImage.link,
            saveToPhotosImage: MEGAAssets.UIImage.saveToPhotos,
            sendToChatImage: MEGAAssets.UIImage.sendToChat,
            moreListImage: MEGAAssets.UIImage.moreList
        ),
        recentlyWatchedAssets: RecentlyWatchedAssets(
            emptyView: .init(
                recentsEmptyStateImage: MEGAAssets.UIImage.recentlyWatchedVideosEmptyState
            )
        )
    )}
}
