import SwiftUI
import Video

extension VideoConfig {
    
    static let live = VideoConfig(
        videoListAssets: VideoConfig.VideoListAssets(
            noResultVideoImage: UIImage.noResultsVideo
        ),
        rowAssets: VideoConfig.RowAssets(
            favoriteImage: UIImage.favouriteThumbnail,
            playImage: UIImage.rectangleVideoStack,
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
            primaryTextColor: Color.primary,
            secondaryLightTextColor: Color.gray515151,
            secondaryDarkTextColor: Color.grayD1D1D1,
            whiteColor: MEGAAppColor.White._FFFFFF.color,
            durationTextBackgroundColor: MEGAAppColor.Black._161616.color.opacity(0.5),
            tabActiveIndicatorColor: Color(UIColor.redF30C14),
            tabInactiveIndicatorColor: Color.clear,
            tabInactiveTextColor: Color.gray515151,
            addPlaylistButtonBackgroundColor: Color.videoPlaylistAddButtonBackground,
            chromeTabOrToolBarLight: Color.navigationBg,
            chromeTabOrToolBarDark: MEGAAppColor.Black._161616.color,
            navigationBarLightColor: Color.navigationBg,
            navigationBarDarkColor: MEGAAppColor.Black._161616.color,
            emptyFavoriteThumbnailLightBackgroundColor: Color.grayE2E2E2,
            emptyFavoriteThumbnailDarkBackgroundColor: MEGAAppColor.Black._2C2C2E.color,
            emptyFavoriteThumbnaillImageLightForegroundColor: Color.grayBBBBBB,
            emptyFavoriteThumbnaillImageDarkForegroundColor: Color.grayD1D1D1
        ),
        toolbarAssets: VideoConfig.ToolbarAssets(
            offlineImage: UIImage.offline,
            linkImage: UIImage.link,
            saveToPhotosImage: UIImage.saveToPhotos,
            hudMinusImage: UIImage.hudMinus,
            moreListImage: UIImage.moreList
        )
    )
}
