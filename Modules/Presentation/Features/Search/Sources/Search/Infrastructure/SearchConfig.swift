import MEGASwiftUI
import SwiftUI
import UIKit

/// Any configuration needed for search module assets, behaviour or styling
/// currently on chips colors are specified here
public struct SearchConfig {
    
    public let chipAssets: ChipAssets
    public let emptyViewAssetFactory: (SearchChipEntity?) -> EmptyViewAssets
    public let rowAssets: RowAssets
    public let colorAssets: ColorAssets
    public let contextPreviewFactory: ContextPreviewFactory
    
    public init(
        chipAssets: ChipAssets,
        emptyViewAssetFactory: @escaping (SearchChipEntity?) -> EmptyViewAssets,
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
        public let F7F7F7: Color
        public let _161616: Color
        public let _545458: Color
        public let CE0A11: Color
        public let F30C14: Color
        public let F95C61: Color
        public let F7363D: Color
        public let _1C1C1E: Color

        public init(
            F7F7F7: Color,
            _161616: Color,
            _545458: Color,
            CE0A11: Color,
            F30C14: Color,
            F95C61: Color,
            F7363D: Color,
            _1C1C1E: Color
        ) {
            self.F7F7F7 = F7F7F7
            self._161616 = _161616
            self._545458 = _545458
            self.CE0A11 = CE0A11
            self.F30C14 = F30C14
            self.F95C61 = F95C61
            self.F7363D = F7363D
            self._1C1C1E = _1C1C1E
        }
    }
}
