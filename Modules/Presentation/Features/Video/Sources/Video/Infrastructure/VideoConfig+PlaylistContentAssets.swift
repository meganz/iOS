import SwiftUI
import UIKit

extension VideoConfig {
    
    public struct PlaylistContentAssets: Equatable {
        let headerView: HeaderView
        let favouritesEmptyStateImage: UIImage
        let noResultVideoPlaylistImage: UIImage
        let videoPlaylistThumbnailFallbackImage: UIImage
        
        public init(
            headerView: HeaderView,
            favouritesEmptyStateImage: UIImage,
            noResultVideoPlaylistImage: UIImage,
            videoPlaylistThumbnailFallbackImage: UIImage
        ) {
            self.headerView = headerView
            self.favouritesEmptyStateImage = favouritesEmptyStateImage
            self.noResultVideoPlaylistImage = noResultVideoPlaylistImage
            self.videoPlaylistThumbnailFallbackImage = videoPlaylistThumbnailFallbackImage
        }
        
        public struct HeaderView: Equatable {
            let image: HeaderView.ImageAssets
            let color: ColorPalette
            
            public init(
                image: HeaderView.ImageAssets,
                color: ColorPalette
            ) {
                self.image = image
                self.color = color
            }
            
            public struct ImageAssets: Equatable {
                let dotSeparatorImage: UIImage
                let publicLinkImage: UIImage
                let addButtonImage: UIImage
                let playButtonImage: UIImage
                
                public init(
                    dotSeparatorImage: UIImage,
                    publicLinkImage: UIImage,
                    addButtonImage: UIImage,
                    playButtonImage: UIImage
                ) {
                    self.dotSeparatorImage = dotSeparatorImage
                    self.publicLinkImage = publicLinkImage
                    self.addButtonImage = addButtonImage
                    self.playButtonImage = playButtonImage
                }
            }
            
            public struct ColorPalette: Equatable {
                let pageBackgroundColor: Color
                let thumbnailBackgroundColor: Color
                let primaryTextColor: Color
                let secondaryTextColor: Color
                let secondaryIconColor: Color
                let buttonTintColor: Color
                
                public init(
                    pageBackgroundColor: Color,
                    thumbnailBackgroundColor: Color,
                    primaryTextColor: Color,
                    secondaryTextColor: Color,
                    secondaryIconColor: Color,
                    buttonTintColor: Color
                ) {
                    self.pageBackgroundColor = pageBackgroundColor
                    self.thumbnailBackgroundColor = thumbnailBackgroundColor
                    self.primaryTextColor = primaryTextColor
                    self.secondaryTextColor = secondaryTextColor
                    self.secondaryIconColor = secondaryIconColor
                    self.buttonTintColor = buttonTintColor
                }
            }
        }
    }
    
}
