import MEGAPresentation
import UIKit

public struct PhotosBrowserConfiguration {
    let displayMode: PhotosBrowserDisplayMode
    let library: MediaLibrary
    
    public init(displayMode: PhotosBrowserDisplayMode, library: MediaLibrary) {
        self.displayMode = displayMode
        self.library = library
    }
}
