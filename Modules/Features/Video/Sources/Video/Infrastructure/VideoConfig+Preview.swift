import MEGAAssets
import MEGADesignToken
import MEGASwiftUI
import SwiftUI

extension VideoConfig {
    
    /// Internal Video SPM module Dependencies helper for SwiftUI
    static let preview = VideoConfig(
        videoListAssets: VideoListAssets(
            noResultVideoImage: MEGAAssets.UIImage.image(named: "noResultsVideoV2")!,
            checkmarkImage: MEGAAssets.UIImage.image(named: "turquoise_checkmark")!,
            chipDownArrowImage: MEGAAssets.UIImage.image(named: "filterChipDownArrow")!
        ),
        rowAssets: RowAssets(
            favoriteImage: MEGAAssets.UIImage.image(named: "favouriteThumbnail")!,
            playImage: MEGAAssets.UIImage.image(named: "blackPlayButton")!,
            publicLinkImage: MEGAAssets.UIImage.image(named: "linked")!,
            moreImage: MEGAAssets.UIImage.image(named: "moreList")!,
            addPlaylistImage: MEGAAssets.UIImage.image(named: "navigationbar_add")!,
            rectangleVideoStackPlaylistImage: MEGAAssets.UIImage.image(named: "rectangleVideoStack")!,
            favouritePlaylistThumbnailImage: MEGAAssets.UIImage.image(named: "FavouritePlaylistThumbnail")!,
            grabberIconImage: MEGAAssets.UIImage.image(named: "grabberIcon")!,
            downloadedImage: MEGAAssets.UIImage.image(named: "downloaded")!,
            labelAssets: VideoConfig.RowAssets.LabelAssets(
                redImage: MEGAAssets.UIImage.image(named: "RedSmall")!,
                orangeImage: MEGAAssets.UIImage.image(named: "OrangeSmall")!,
                yellowImage: MEGAAssets.UIImage.image(named: "YellowSmall")!,
                greenImage: MEGAAssets.UIImage.image(named: "GreenSmall")!,
                blueImage: MEGAAssets.UIImage.image(named: "BlueSmall")!,
                purpleImage: MEGAAssets.UIImage.image(named: "PurpleSmall")!,
                greyImage: MEGAAssets.UIImage.image(named: "GreySmall")!
            )
        ),
        colorAssets: ColorAssets(
            primaryTextColor: TokenColors.Text.primary.swiftUI,
            secondaryTextColor: TokenColors.Text.secondary.swiftUI,
            primaryIconColor: TokenColors.Icon.primary.swiftUI,
            secondaryIconColor: TokenColors.Icon.secondary.swiftUI,
            pageBackgroundColor: TokenColors.Background.page.swiftUI,
            whiteColor: TokenColors.Text.onColor.swiftUI,
            durationTextColor: Color(uiColor: MEGAAssets.UIColor.color(named: "black_161616")!).opacity(0.5),
            tabActiveIndicatorColor: Color(uiColor: MEGAAssets.UIColor.color(named: "red_F30C14")!),
            tabInactiveIndicatorColor: Color.clear,
            tabInactiveTextColor: Color(uiColor: MEGAAssets.UIColor.color(named: "gray_515151")!),
            addPlaylistButtonTextColor: TokenColors.Text.inverseAccent.swiftUI,
            addPlaylistButtonBackgroundColor: TokenColors.Icon.accent.swiftUI,
            toolbarBackgroundColor: Color(uiColor: MEGAAssets.UIColor.color(named: "navigationBgColor")!),
            navigationBgColor: Color(uiColor: MEGAAssets.UIColor.color(named: "navigationBgColor")!),
            emptyFavoriteThumbnailBackgroundColor: TokenColors.Background.surface3.swiftUI,
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
            videoFilterChipInactiveBackgroundColor: TokenColors.Background.surface2.swiftUI,
            highlightedTextColor: TokenColors.Notifications.notificationSuccess.swiftUI
        ),
        toolbarAssets: ToolbarAssets(
            offlineImage: MEGAAssets.UIImage.image(named: "offline")!,
            linkImage: MEGAAssets.UIImage.image(named: "link")!,
            saveToPhotosImage: MEGAAssets.UIImage.image(named: "saveToPhotos")!,
            sendToChatImage: MEGAAssets.UIImage.image(named: "sendToChat")!,
            moreListImage: MEGAAssets.UIImage.image(named: "moreList")!
        ),
        recentlyWatchedAssets: RecentlyWatchedAssets(
            emptyView: .init(
                recentsEmptyStateImage: MEGAAssets.UIImage.image(named: "recentlyWatchedVideosEmptyState")!
            )
        )
    )
}
