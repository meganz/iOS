import SwiftUI

extension VideoConfig {
    
    public struct RecentlyWatchedAssets: Equatable {
        let emptyView: EmptyView
        let listView: ListView
        
        public init(
            emptyView: EmptyView,
            listView: ListView
        ) {
            self.emptyView = emptyView
            self.listView = listView
        }
        
        public struct EmptyView: Equatable {
            let color: ColorPalette
            let recentsEmptyStateImage: UIImage
            
            public init(
                color: ColorPalette,
                recentsEmptyStateImage: UIImage
            ) {
                self.color = color
                self.recentsEmptyStateImage = recentsEmptyStateImage
            }
            
            public struct ColorPalette: Equatable {
                let pageBackgroundColor: Color
                let textColor: Color
                let iconColor: Color
                
                public init(
                    pageBackgroundColor: Color,
                    textColor: Color,
                    iconColor: Color
                ) {
                    self.pageBackgroundColor = pageBackgroundColor
                    self.textColor = textColor
                    self.iconColor = iconColor
                }
            }
        }
        
        public struct ListView: Equatable {
            let header: Header
            let cell: Cell
            
            public init(header: Header, cell: Cell) {
                self.header = header
                self.cell = cell
            }
            
            public struct Header: Equatable {
                let color: ColorPalette
                
                public init(color: ColorPalette) {
                    self.color = color
                }
                
                public struct ColorPalette: Equatable {
                    let primaryTextColor: Color
                    let pageBackgroundColor: Color
                    
                    public init(
                        primaryTextColor: Color,
                        pageBackgroundColor: Color
                    ) {
                        self.primaryTextColor = primaryTextColor
                        self.pageBackgroundColor = pageBackgroundColor
                    }
                }
            }
            
            public struct Cell: Equatable {
                let color: ColorPalette
                
                public init(color: ColorPalette) {
                    self.color = color
                }
                
                public struct ColorPalette: Equatable {
                    let primaryTextColor: Color
                    let secondaryTextColor: Color
                    let secondaryIconColor: Color
                    let durationTextColor: Color
                    let durationTextBackgroundColor: Color
                    let pageBackgroundColor: Color
                    let progressBarActiveColor: Color
                    let progressBarBackgroundColor: Color
                    
                    public init(
                        primaryTextColor: Color,
                        secondaryTextColor: Color,
                        secondaryIconColor: Color,
                        durationTextColor: Color,
                        durationTextBackgroundColor: Color,
                        pageBackgroundColor: Color,
                        progressBarActiveColor: Color,
                        progressBarBackgroundColor: Color
                    ) {
                        self.primaryTextColor = primaryTextColor
                        self.secondaryTextColor = secondaryTextColor
                        self.secondaryIconColor = secondaryIconColor
                        self.durationTextColor = durationTextColor
                        self.durationTextBackgroundColor = durationTextBackgroundColor
                        self.pageBackgroundColor = pageBackgroundColor
                        self.progressBarActiveColor = progressBarActiveColor
                        self.progressBarBackgroundColor = progressBarBackgroundColor
                    }
                }
            }
        }
    }
}

extension VideoConfig {
    var recentsEmptyStateImage: UIImage { recentlyWatchedAssets.emptyView.recentsEmptyStateImage }
}
