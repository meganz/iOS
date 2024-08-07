import MEGAPresentation
import UIKit

public struct PhotosBrowserConfiguration {
    let displayMode: PhotosBrowserDisplayMode
    let toolbarImages: [UIImage]
    
    public init(displayMode: PhotosBrowserDisplayMode, toolbarImages: [UIImage]) {
        self.displayMode = displayMode
        self.toolbarImages = toolbarImages
    }
}
