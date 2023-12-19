#if DEBUG
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
            playImage: UIImage(systemName: "play.circle.fill")!,
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
            secondaryLightTextColor: Color(uiColor: MEGAAssetsPreviewColorProvider.color(named: "gray_515151")!),
            secondaryDarkTextColor: Color(uiColor: MEGAAssetsPreviewColorProvider.color(named: "gray_D1D1D1")!),
            whiteColor: .white,
            durationTextBackgroundColor: Color(uiColor: MEGAAssetsPreviewColorProvider.color(named: "black_161616")!).opacity(0.5),
            tabActiveIndicatorColor: Color(uiColor: MEGAAssetsPreviewColorProvider.color(named: "red_F30C14")!),
            tabInactiveIndicatorColor: Color.clear,
            tabInactiveTextColor: Color(uiColor: MEGAAssetsPreviewColorProvider.color(named: "gray_515151")!),
            addPlaylistButtonBackgroundColor: Color(uiColor: MEGAAssetsPreviewColorProvider.color(named: "videoPlaylist_addButtonBackground")!),
            chromeTabOrToolBarLight: Color(uiColor: MEGAAssetsPreviewColorProvider.color(named: "navigationBgColor")!),
            chromeTabOrToolBarDark: Color(uiColor: MEGAAssetsPreviewColorProvider.color(named: "black_161616")!),
            navigationBarLightColor: Color(uiColor: MEGAAssetsPreviewColorProvider.color(named: "navigationBgColor")!),
            navigationBarDarkColor: Color(uiColor: MEGAAssetsPreviewColorProvider.color(named: "black_161616")!),
            emptyFavoriteThumbnailLightBackgroundColor: Color(uiColor: MEGAAssetsPreviewColorProvider.color(named: "gray_E2E2E2")!),
            emptyFavoriteThumbnailDarkBackgroundColor: Color(uiColor: MEGAAssetsPreviewColorProvider.color(named: "black_2c2c2e")!),
            emptyFavoriteThumbnaillImageLightForegroundColor: Color(uiColor: MEGAAssetsPreviewColorProvider.color(named: "gray_BBBBBB")!),
            emptyFavoriteThumbnaillImageDarkForegroundColor: Color(uiColor: MEGAAssetsPreviewColorProvider.color(named: "gray_D1D1D1")!)
        ),
        toolbarAssets: ToolbarAssets(
            offlineImage: MEGAAssetsPreviewImageProvider.image(named: "offline")!,
            linkImage: MEGAAssetsPreviewImageProvider.image(named: "link")!,
            saveToPhotosImage: MEGAAssetsPreviewImageProvider.image(named: "saveToPhotos")!,
            hudMinusImage: MEGAAssetsPreviewImageProvider.image(named: "hudMinus")!,
            moreListImage: MEGAAssetsPreviewImageProvider.image(named: "moreList")!
        )
    )
}
#endif
