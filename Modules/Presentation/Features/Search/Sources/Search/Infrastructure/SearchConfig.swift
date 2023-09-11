import SwiftUI

/// Any configuration needed for search module assets, behaviour or styling
/// currently on chips colors are specified here
public struct SearchConfig {
    public init(chipAssets: ChipAssets) {
        self.chipAssets = chipAssets
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
    
    public let chipAssets: ChipAssets
}
