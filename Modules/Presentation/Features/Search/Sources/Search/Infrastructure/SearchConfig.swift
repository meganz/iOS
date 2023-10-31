import MEGASwiftUI
import SwiftUI
import UIKit

/// Any configuration needed for search module assets, behaviour or styling
/// currently on chips colors are specified here
public struct SearchConfig {
    
    public let chipAssets: ChipAssets
    public let emptyViewAssetFactory: (SearchChipEntity?) -> EmptyViewAssets
    public let rowAssets: RowAssets
    public let contextPreviewFactory: ContextPreviewFactory
    
    public init(
        chipAssets: ChipAssets,
        emptyViewAssetFactory: @escaping (SearchChipEntity?) -> EmptyViewAssets,
        rowAssets: RowAssets,
        contextPreviewFactory: ContextPreviewFactory
    ) {
        self.chipAssets = chipAssets
        self.emptyViewAssetFactory = emptyViewAssetFactory
        self.rowAssets = rowAssets
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
            selectedForeground: Color,
            selectedBackground: Color,
            normalForeground: Color,
            normalBackground: Color
        ) {
            self.selectedForeground = selectedForeground
            self.selectedBackground = selectedBackground
            self.normalForeground = normalForeground
            self.normalBackground = normalBackground
        }
        
        let selectedForeground: Color
        let selectedBackground: Color
        
        let normalForeground: Color
        let normalBackground: Color
    }
    
    public struct EmptyViewAssets {
        public let image: Image
        public let title: String
        public let foregroundColor: Color
        
        public init(
            image: Image,
            title: String,
            foregroundColor: Color
        ) {
            self.image = image
            self.title = title
            self.foregroundColor = foregroundColor
        }
    }
    
    public struct RowAssets {
        public init(
            contextImage: UIImage,
            itemSelected: UIImage,
            itemUnselected: UIImage
        ) {
            self.contextImage = contextImage
            self.itemSelected = itemSelected
            self.itemUnselected = itemUnselected
        }
        
        public let contextImage: UIImage
        public let itemSelected: UIImage
        public let itemUnselected: UIImage
    }
}
