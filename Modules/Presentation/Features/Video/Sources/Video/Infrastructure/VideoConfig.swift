import SwiftUI

/// Any configuration needed for video module assets, behaviour or styling
public struct VideoConfig: Equatable {
    
    public let videoListAssets: VideoListAssets
    public let rowAssets: RowAssets
    public let colorAssets: ColorAssets
    public let toolbarAssets: ToolbarAssets
    
    /// Configuration Dependencies that needs to be passed from Main module.
    /// - Parameters:
    ///   - videoListAssets: contains assets for videoList
    ///   - rowAssets: contains assets for video row cell
    ///   - colorAssets: contains assets color assets
    ///   - toolbarAssets: contains assets toolbar
    public init(
        videoListAssets: VideoListAssets,
        rowAssets: RowAssets,
        colorAssets: ColorAssets,
        toolbarAssets: ToolbarAssets
    ) {
        self.videoListAssets = videoListAssets
        self.rowAssets = rowAssets
        self.colorAssets = colorAssets
        self.toolbarAssets = toolbarAssets
    }
    
    public struct VideoListAssets: Equatable {
        
        public let noResultVideoImage: UIImage
        
        public init(noResultVideoImage: UIImage) {
            self.noResultVideoImage = noResultVideoImage
        }
    }
    
    public struct RowAssets: Equatable {
        
        public let favoriteImage: UIImage
        public let playImage: UIImage
        public let publicLinkImage: UIImage
        public let moreImage: UIImage
        public let addPlaylistImage: UIImage
        public let rectangleVideoStackPlaylistImage: UIImage
        public let favouritePlaylistThumbnailImage: UIImage
        public let labelAssets: LabelAssets
        
        /// Assets for Video cell view
        /// - Parameters:
        ///   - favoriteImage: Image for favorite icon
        ///   - playImage: Image for center play icon
        ///   - publicLinkImage: Image for public link icon
        ///   - moreImage: Image for more icon
        ///   - rectangleVideoStackPlaylistImage: Image for playlist icon
        ///   - favouritePlaylistThumbnailImage: Image for favorite playlist center icon
        ///   - labelAssets: Assets for labels
        public init(
            favoriteImage: UIImage,
            playImage: UIImage,
            publicLinkImage: UIImage,
            moreImage: UIImage,
            addPlaylistImage: UIImage,
            rectangleVideoStackPlaylistImage: UIImage,
            favouritePlaylistThumbnailImage: UIImage,
            labelAssets: LabelAssets
        ) {
            self.favoriteImage = favoriteImage
            self.playImage = playImage
            self.publicLinkImage = publicLinkImage
            self.moreImage = moreImage
            self.addPlaylistImage = addPlaylistImage
            self.rectangleVideoStackPlaylistImage = rectangleVideoStackPlaylistImage
            self.favouritePlaylistThumbnailImage = favouritePlaylistThumbnailImage
            self.labelAssets = labelAssets
        }
        
        public struct LabelAssets: Equatable {
            
            public let redImage: UIImage
            public let orangeImage: UIImage
            public let yellowImage: UIImage
            public let greenImage: UIImage
            public let blueImage: UIImage
            public let purpleImage: UIImage
            public let greyImage: UIImage
            
            /// Assets for label images is available for Dependency Injection. Later on, we can inject from Main module with  :
            /// NSString *labelString = [[MEGANode stringForNodeLabel:node.label] stringByAppendingString:@"Small"];
            /// UIImage? *redImage = [UIImage? imageNamed:labelString];
            /// - Parameters:
            ///   - redImage: image for red label icon
            ///   - orangeImage: image for orange label icon
            ///   - yellowImage: image for yellow label icon
            ///   - greenImage: image for green label icon
            ///   - blueImage: image for blue label icon
            ///   - purpleImage: image for purple label icon
            ///   - greyImage: image for grey label icon
            public init(
                redImage: UIImage,
                orangeImage: UIImage,
                yellowImage: UIImage,
                greenImage: UIImage,
                blueImage: UIImage,
                purpleImage: UIImage,
                greyImage: UIImage
            ) {
                self.redImage = redImage
                self.orangeImage = orangeImage
                self.yellowImage = yellowImage
                self.greenImage = greenImage
                self.blueImage = blueImage
                self.purpleImage = purpleImage
                self.greyImage = greyImage
            }
        }
    }
    
    public struct ToolbarAssets: Equatable {
        public let offlineImage: UIImage
        public let linkImage: UIImage
        public let saveToPhotosImage: UIImage
        public let hudMinusImage: UIImage
        public let moreListImage: UIImage
        
        public init(
            offlineImage: UIImage,
            linkImage: UIImage,
            saveToPhotosImage: UIImage,
            hudMinusImage: UIImage,
            moreListImage: UIImage
        ) {
            self.offlineImage = offlineImage
            self.linkImage = linkImage
            self.saveToPhotosImage = saveToPhotosImage
            self.hudMinusImage = hudMinusImage
            self.moreListImage = moreListImage
        }
    }
    
    public struct ColorAssets: Equatable {
        
        public let primaryTextColor: Color
        public let secondaryLightTextColor: Color
        public let secondaryDarkTextColor: Color
        public let whiteColor: Color
        public let durationTextBackgroundColor: Color
        public let tabActiveIndicatorColor: Color
        public let tabInactiveIndicatorColor: Color
        public let tabInactiveTextColor: Color
        public let addPlaylistButtonBackgroundColor: Color
        public let chromeTabOrToolBarLight: Color
        public let chromeTabOrToolBarDark: Color
        public let navigationBarLightColor: Color
        public let navigationBarDarkColor: Color
        public let emptyFavoriteThumbnailLightBackgroundColor: Color
        public let emptyFavoriteThumbnailDarkBackgroundColor: Color
        public let emptyFavoriteThumbnaillImageLightForegroundColor: Color
        public let emptyFavoriteThumbnaillImageDarkForegroundColor: Color
        
        /// Specify colors that needs to be injected from Main module.
        public init(
            primaryTextColor: Color,
            secondaryLightTextColor: Color,
            secondaryDarkTextColor: Color,
            whiteColor: Color,
            durationTextBackgroundColor: Color,
            tabActiveIndicatorColor: Color,
            tabInactiveIndicatorColor: Color,
            tabInactiveTextColor: Color,
            addPlaylistButtonBackgroundColor: Color,
            chromeTabOrToolBarLight: Color,
            chromeTabOrToolBarDark: Color,
            navigationBarLightColor: Color,
            navigationBarDarkColor: Color,
            emptyFavoriteThumbnailLightBackgroundColor: Color,
            emptyFavoriteThumbnailDarkBackgroundColor: Color,
            emptyFavoriteThumbnaillImageLightForegroundColor: Color,
            emptyFavoriteThumbnaillImageDarkForegroundColor: Color
        ) {
            self.primaryTextColor = primaryTextColor
            self.secondaryLightTextColor = secondaryLightTextColor
            self.secondaryDarkTextColor = secondaryDarkTextColor
            self.whiteColor = whiteColor
            self.durationTextBackgroundColor = durationTextBackgroundColor
            self.tabActiveIndicatorColor = tabActiveIndicatorColor
            self.tabInactiveIndicatorColor = tabInactiveIndicatorColor
            self.tabInactiveTextColor = tabInactiveTextColor
            self.addPlaylistButtonBackgroundColor = addPlaylistButtonBackgroundColor
            self.chromeTabOrToolBarLight = chromeTabOrToolBarLight
            self.chromeTabOrToolBarDark = chromeTabOrToolBarDark
            self.navigationBarLightColor = navigationBarLightColor
            self.navigationBarDarkColor = navigationBarDarkColor
            self.emptyFavoriteThumbnailLightBackgroundColor = emptyFavoriteThumbnailLightBackgroundColor
            self.emptyFavoriteThumbnailDarkBackgroundColor = emptyFavoriteThumbnailDarkBackgroundColor
            self.emptyFavoriteThumbnaillImageLightForegroundColor = emptyFavoriteThumbnaillImageLightForegroundColor
            self.emptyFavoriteThumbnaillImageDarkForegroundColor = emptyFavoriteThumbnaillImageDarkForegroundColor
        }
    }
}
