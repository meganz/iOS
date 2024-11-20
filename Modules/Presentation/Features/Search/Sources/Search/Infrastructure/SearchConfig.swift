import MEGASwiftUI
import SwiftUI
import UIKit

/// Any configuration needed for search module assets, behaviour or styling
/// currently on chips colors are specified here
public struct SearchConfig {
    
    public let chipAssets: ChipAssets
    public let emptyViewAssetFactory: (SearchChipEntity?, SearchQuery) -> EmptyViewAssets
    public let rowAssets: RowAssets
    public let colorAssets: ColorAssets
    public let contextPreviewFactory: ContextPreviewFactory
    
    public init(
        chipAssets: ChipAssets,
        emptyViewAssetFactory: @escaping (SearchChipEntity?, SearchQuery) -> EmptyViewAssets,
        rowAssets: RowAssets,
        colorAssets: ColorAssets,
        contextPreviewFactory: ContextPreviewFactory
    ) {
        self.chipAssets = chipAssets
        self.emptyViewAssetFactory = emptyViewAssetFactory
        self.rowAssets = rowAssets
        self.colorAssets = colorAssets
        self.contextPreviewFactory = contextPreviewFactory
    }
    
    public struct ContextPreviewFactory {
        public let previewContentForResult: (SearchResult) -> PreviewContent
        public init(
            previewContentForResult: @escaping (SearchResult) -> PreviewContent
        ) {
            self.previewContentForResult = previewContentForResult
        }
    }
    
    public struct ChipAssets {
        public init(
            selectionIndicatorImage: UIImage,
            closeIcon: UIImage,
            selectedForeground: Color,
            selectedBackground: Color,
            normalForeground: Color,
            normalBackground: Color
        ) {
            self.selectionIndicatorImage = selectionIndicatorImage
            self.closeIcon = closeIcon
            self.selectedForeground = selectedForeground
            self.selectedBackground = selectedBackground
            self.normalForeground = normalForeground
            self.normalBackground = normalBackground
        }

        let selectionIndicatorImage: UIImage
        let closeIcon: UIImage

        let selectedForeground: Color
        let selectedBackground: Color
        
        let normalForeground: Color
        let normalBackground: Color
    }
    
    public struct EmptyViewAssets {
        /// Represents a menu option shown when the button is pressed.
        ///
        /// - Note: Instance of this struct is used along with `Action`. For more info see `Action` documentation.
        public struct MenuOption {
            public let title: String
            public let image: Image
            public let handler: () -> Void

            public init(title: String, image: Image, handler: @escaping () -> Void) {
                self.title = title
                self.image = image
                self.handler = handler
            }
        }

        /// Represents an element in the `EmptyViewAssets` that the user can perform.
        /// It can be a button or a menu.
        ///
        /// # Example 1: Menu
        /// ```
        /// let menuAction = Action(
        ///   title: "Title",
        ///   backgroundColor: { _ in .red },
        ///   menu: [
        ///     .init(
        ///       title: "MenuOption 1",
        ///       titleTextColor: { _ in nil }
        ///       image: Image(systemName: "plus"),
        ///       handler: {}
        ///     )
        ///   ],
        ///   handler: nil
        /// )
        /// ```
        /// # Example 2: Button
        /// ```
        /// let buttonAction = Action(
        ///   title: "Title",
        ///   titleTextColor: { _ in .black }
        ///   backgroundColor: { _ in .red },
        ///   menu: [],
        ///   handler: {}
        /// )
        /// ```
         public struct Action {
            public let title: String
            public let titleTextColor: Color?
            public let backgroundColor: Color
            public let menu: [MenuOption]
            public typealias Handler = () -> Void
            public let handler: Handler?

            public init(
                title: String,
                titleTextColor: Color?,
                backgroundColor: Color,
                menu: [MenuOption],
                handler: Handler? = nil) {
                self.title = title
                self.titleTextColor = titleTextColor
                self.backgroundColor = backgroundColor
                self.menu = menu
                self.handler = handler
            }
        }

        public let image: Image
        public let title: String
        public let titleTextColor: Color
        public let actions: [Action]

        public init(
            image: Image,
            title: String,
            titleTextColor: Color,
            actions: [Action] = []
        ) {
            self.image = image
            self.title = title
            self.titleTextColor = titleTextColor
            self.actions = actions
        }
    }
    
    public struct RowAssets {
        public init(
            contextImage: UIImage,
            itemSelected: UIImage,
            itemUnselected: UIImage,
            playImage: UIImage,
            downloadedImage: UIImage,
            moreList: UIImage,
            moreGrid: UIImage
        ) {
            self.contextImage = contextImage
            self.itemSelected = itemSelected
            self.itemUnselected = itemUnselected
            self.playImage = playImage
            self.downloadedImage = downloadedImage
            self.moreList = moreList
            self.moreGrid = moreGrid
        }

        public let contextImage: UIImage
        public let itemSelected: UIImage
        public let itemUnselected: UIImage
        public let playImage: UIImage
        public let downloadedImage: UIImage
        public let moreList: UIImage
        public let moreGrid: UIImage
    }

    public struct ColorAssets {
        
        /// Color for the border of the items in thumbnail mode in unselected state
        public let unselectedBorderColor: Color
        /// Color for the border of the items in thumbnail mode in selected state
        public let selectedBorderColor: Color
        
        public let titleTextColor: Color
        public let subtitleTextColor: Color
        public let vibrantColor: Color
        public let resultPropertyColor: Color
        
        // Color for the text of the footer of vertical thumbnail mode
        public let verticalThumbnailFooterText: Color
        
        // Color for the background of the footer of vertical thumbnail mode
        public let verticalThumbnailFooterBackground: Color
        
        // Color for the background of the preview icon
        public let verticalThumbnailPreviewBackground: Color

        // Color for the background of the property icons in thumbnail mode
        public let verticalThumbnailTopIconsBackground: Color
        
        // Important note: The correct source of truth for this color in Figma is the "Common UI" page, not "Cloud Drive" page
        public let listRowSeparator: Color
        
        public let checkmarkBackgroundTintColor: Color

        public init(
            unselectedBorderColor: Color,
            selectedBorderColor: Color,
            titleTextColor: Color,
            subtitleTextColor: Color,
            vibrantColor: Color,
            resultPropertyColor: Color,
            verticalThumbnailFooterText: Color,
            verticalThumbnailFooterBackground: Color,
            verticalThumbnailPreviewBackground: Color,
            verticalThumbnailTopIconsBackground: Color,
            listRowSeparator: Color,
            checkmarkBackgroundTintColor: Color
        ) {
            self.unselectedBorderColor = unselectedBorderColor
            self.selectedBorderColor = selectedBorderColor
            self.titleTextColor = titleTextColor
            self.subtitleTextColor = subtitleTextColor
            self.vibrantColor = vibrantColor
            self.resultPropertyColor = resultPropertyColor
            
            self.verticalThumbnailFooterText = verticalThumbnailFooterText
            self.verticalThumbnailFooterBackground = verticalThumbnailFooterBackground
            self.verticalThumbnailPreviewBackground = verticalThumbnailPreviewBackground
            self.verticalThumbnailTopIconsBackground = verticalThumbnailTopIconsBackground
            
            self.listRowSeparator = listRowSeparator
            self.checkmarkBackgroundTintColor = checkmarkBackgroundTintColor
        }
    }
}
