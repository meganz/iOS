import MEGADesignToken
import SwiftUI
import Video

extension VideoConfig {
    
    static func live(isDesignTokenEnabled: Bool) -> VideoConfig { VideoConfig(
        videoListAssets: VideoConfig.VideoListAssets(
            noResultVideoImage: UIImage.noResultsVideo
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
            primaryTextColor: isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : Color.primary,
            secondaryTextColor: isDesignTokenEnabled ? TokenColors.Text.secondary.swiftUI : Color.secondary,
            secondaryIconColor: isDesignTokenEnabled ? TokenColors.Icon.secondary.swiftUI : Color.secondary,
            pageBackgroundColor: isDesignTokenEnabled ? TokenColors.Background.page.swiftUI : Color.clear,
            whiteColor: MEGAAppColor.White._FFFFFF.color,
            durationTextColor: isDesignTokenEnabled ? TokenColors.Text.primary.swiftUI : Color.white,
            tabActiveIndicatorColor: isDesignTokenEnabled ? TokenColors.Button.brand.swiftUI : MEGAAppColor.Red._F30C14.color,
            tabInactiveIndicatorColor: isDesignTokenEnabled ? TokenColors.Background.surface1.swiftUI : Color.clear,
            tabInactiveTextColor: isDesignTokenEnabled ? TokenColors.Icon.secondary.swiftUI : MEGAAppColor.Gray._515151.color,
            addPlaylistButtonBackgroundColor: Color.videoPlaylistAddButtonBackground,
            toolbarBackgroundColor: isDesignTokenEnabled ? TokenColors.Background.surface1.swiftUI : Color.navigationBg,
            navigationBgColor: isDesignTokenEnabled ? TokenColors.Background.surface1.swiftUI : Color.navigationBg,
            emptyFavoriteThumbnailLightBackgroundColor: MEGAAppColor.Gray._E2E2E2.color,
            emptyFavoriteThumbnailDarkBackgroundColor: MEGAAppColor.Black._2C2C2E.color,
            emptyFavoriteThumbnaillImageLightForegroundColor: MEGAAppColor.Gray._BBBBBB.color,
            emptyFavoriteThumbnaillImageDarkForegroundColor: MEGAAppColor.Gray._D1D1D1.color,
            videoCellSecondaryLightTextColor: MEGAAppColor.Gray._BBBBBB.color,
            videoCellSecondaryDarkTextColor: MEGAAppColor.Gray._D1D1D1.color,
            videoThumbnailImageViewPlaceholderBackgroundColor: MEGAAppColor.Videos.videoThumbnailImageViewPlaceholderBackgroundColor.color,
            videoThumbnailDurationTextBackgroundColor: MEGAAppColor.Videos.videoThumbnailDurationTextBackgroundColor.color
        ),
        toolbarAssets: VideoConfig.ToolbarAssets(
            offlineImage: UIImage.offline,
            linkImage: UIImage.link,
            saveToPhotosImage: UIImage.saveToPhotos,
            hudMinusImage: UIImage.hudMinus,
            moreListImage: UIImage.moreList
        )
    )}
}
