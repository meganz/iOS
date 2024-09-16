import SwiftUI

/// Any configuration needed for video module assets, behaviour or styling
public struct VideoConfig: Equatable {
    
    public let videoListAssets: VideoListAssets
    public let rowAssets: RowAssets
    public let colorAssets: ColorAssets
    public let toolbarAssets: ToolbarAssets
    public let recentlyWatchedAssets: RecentlyWatchedAssets
    public let playlistContentAssets: PlaylistContentAssets
    
    /// Configuration Dependencies that needs to be passed from Main module.
    /// - Parameters:
    ///   - videoListAssets: contains assets for videoList
    ///   - rowAssets: contains assets for video row cell
    ///   - colorAssets: contains assets color assets
    ///   - toolbarAssets: contains assets toolbar
    ///   - recentlyWatchedAssets: contains assets for recently watched views
    ///   - playlistContentAssets: contains assets for video playlists content
    public init(
        videoListAssets: VideoListAssets,
        rowAssets: RowAssets,
        colorAssets: ColorAssets,
        toolbarAssets: ToolbarAssets,
        recentlyWatchedAssets: RecentlyWatchedAssets,
        playlistContentAssets: PlaylistContentAssets
    ) {
        self.videoListAssets = videoListAssets
        self.rowAssets = rowAssets
        self.colorAssets = colorAssets
        self.toolbarAssets = toolbarAssets
        self.recentlyWatchedAssets = recentlyWatchedAssets
        self.playlistContentAssets = playlistContentAssets
    }
    
    public struct VideoListAssets: Equatable {
        
        public let noResultVideoImage: UIImage
        public let checkmarkImage: UIImage
        public let chipDownArrowImage: UIImage
        
        public init(
            noResultVideoImage: UIImage,
            checkmarkImage: UIImage,
            chipDownArrowImage: UIImage
        ) {
            self.noResultVideoImage = noResultVideoImage
            self.checkmarkImage = checkmarkImage
            self.chipDownArrowImage = chipDownArrowImage
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
        public let downloadedImage: UIImage
        public let labelAssets: LabelAssets
        
        /// Assets for Video cell view
        /// - Parameters:
        ///   - favoriteImage: Image for favorite icon
        ///   - playImage: Image for center play icon
        ///   - publicLinkImage: Image for public link icon
        ///   - moreImage: Image for more icon
        ///   - rectangleVideoStackPlaylistImage: Image for playlist icon
        ///   - favouritePlaylistThumbnailImage: Image for favorite playlist center icon
        ///   - downloadedImage: Image for downloaded icon
        ///   - labelAssets: Assets for labels
        public init(
            favoriteImage: UIImage,
            playImage: UIImage,
            publicLinkImage: UIImage,
            moreImage: UIImage,
            addPlaylistImage: UIImage,
            rectangleVideoStackPlaylistImage: UIImage,
            favouritePlaylistThumbnailImage: UIImage,
            downloadedImage: UIImage,
            labelAssets: LabelAssets
        ) {
            self.favoriteImage = favoriteImage
            self.playImage = playImage
            self.publicLinkImage = publicLinkImage
            self.moreImage = moreImage
            self.addPlaylistImage = addPlaylistImage
            self.rectangleVideoStackPlaylistImage = rectangleVideoStackPlaylistImage
            self.favouritePlaylistThumbnailImage = favouritePlaylistThumbnailImage
            self.downloadedImage = downloadedImage
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
        public let sendToChatImage: UIImage
        public let moreListImage: UIImage
        
        public init(
            offlineImage: UIImage,
            linkImage: UIImage,
            saveToPhotosImage: UIImage,
            sendToChatImage: UIImage,
            moreListImage: UIImage
        ) {
            self.offlineImage = offlineImage
            self.linkImage = linkImage
            self.saveToPhotosImage = saveToPhotosImage
            self.sendToChatImage = sendToChatImage
            self.moreListImage = moreListImage
        }
    }
    
    public struct ColorAssets: Equatable {
        
        public let primaryTextColor: Color
        public let secondaryTextColor: Color
        public let primaryIconColor: Color
        public let secondaryIconColor: Color
        public let pageBackgroundColor: Color
        public let whiteColor: Color
        public let durationTextColor: Color
        public let tabActiveIndicatorColor: Color
        public let tabInactiveIndicatorColor: Color
        public let tabInactiveTextColor: Color
        public let addPlaylistButtonTextColor: Color
        public let addPlaylistButtonBackgroundColor: Color
        public let toolbarBackgroundColor: Color
        public let navigationBgColor: Color
        public let emptyFavoriteThumbnailBackgroundColor: Color
        public let emptyFavoriteThumbnaillImageForegroundColor: Color
        public let videoThumbnailImageViewPlaceholderBackgroundColor: Color
        public let videoThumbnailDurationTextBackgroundColor: Color
        public let disabledColor: Color
        public let checkmarkColor: Color
        public let bottomSheetBackgroundColor: Color
        public let bottomSheetHeaderBackgroundColor: Color
        public let bottomSheetCellSelectedBackgroundColor: Color
        public let videoFilterChipActiveForegroundColor: Color
        public let videoFilterChipInactiveForegroundColor: Color
        public let videoFilterChipActiveBackgroundColor: Color
        public let videoFilterChipInactiveBackgroundColor: Color
        
        /// Specify colors that needs to be injected from Main module.
        public init(
            primaryTextColor: Color,
            secondaryTextColor: Color,
            primaryIconColor: Color,
            secondaryIconColor: Color,
            pageBackgroundColor: Color,
            whiteColor: Color,
            durationTextColor: Color,
            tabActiveIndicatorColor: Color,
            tabInactiveIndicatorColor: Color,
            tabInactiveTextColor: Color,
            addPlaylistButtonTextColor: Color,
            addPlaylistButtonBackgroundColor: Color,
            toolbarBackgroundColor: Color,
            navigationBgColor: Color,
            emptyFavoriteThumbnailBackgroundColor: Color,
            emptyFavoriteThumbnaillImageForegroundColor: Color,
            videoThumbnailImageViewPlaceholderBackgroundColor: Color,
            videoThumbnailDurationTextBackgroundColor: Color,
            disabledColor: Color,
            checkmarkColor: Color,
            bottomSheetBackgroundColor: Color,
            bottomSheetHeaderBackgroundColor: Color,
            bottomSheetCellSelectedBackgroundColor: Color,
            videoFilterChipActiveForegroundColor: Color,
            videoFilterChipInactiveForegroundColor: Color,
            videoFilterChipActiveBackgroundColor: Color,
            videoFilterChipInactiveBackgroundColor: Color
        ) {
            self.primaryTextColor = primaryTextColor
            self.secondaryTextColor = secondaryTextColor
            self.primaryIconColor = primaryIconColor
            self.secondaryIconColor = secondaryIconColor
            self.pageBackgroundColor = pageBackgroundColor
            self.whiteColor = whiteColor
            self.durationTextColor = durationTextColor
            self.tabActiveIndicatorColor = tabActiveIndicatorColor
            self.tabInactiveIndicatorColor = tabInactiveIndicatorColor
            self.tabInactiveTextColor = tabInactiveTextColor
            self.addPlaylistButtonTextColor = addPlaylistButtonTextColor
            self.addPlaylistButtonBackgroundColor = addPlaylistButtonBackgroundColor
            self.toolbarBackgroundColor = toolbarBackgroundColor
            self.navigationBgColor = navigationBgColor
            self.emptyFavoriteThumbnailBackgroundColor = emptyFavoriteThumbnailBackgroundColor
            self.emptyFavoriteThumbnaillImageForegroundColor = emptyFavoriteThumbnaillImageForegroundColor
            self.videoThumbnailImageViewPlaceholderBackgroundColor = videoThumbnailImageViewPlaceholderBackgroundColor
            self.videoThumbnailDurationTextBackgroundColor = videoThumbnailDurationTextBackgroundColor
            self.disabledColor = disabledColor
            self.checkmarkColor = checkmarkColor
            self.bottomSheetBackgroundColor = bottomSheetBackgroundColor
            self.bottomSheetHeaderBackgroundColor = bottomSheetHeaderBackgroundColor
            self.bottomSheetCellSelectedBackgroundColor = bottomSheetCellSelectedBackgroundColor
            self.videoFilterChipActiveForegroundColor = videoFilterChipActiveForegroundColor
            self.videoFilterChipInactiveForegroundColor = videoFilterChipInactiveForegroundColor
            self.videoFilterChipActiveBackgroundColor = videoFilterChipActiveBackgroundColor
            self.videoFilterChipInactiveBackgroundColor = videoFilterChipInactiveBackgroundColor
        }
    }
}
