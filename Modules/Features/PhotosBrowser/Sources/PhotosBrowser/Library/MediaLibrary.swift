import Foundation
import MEGADomain

public final class MediaLibrary: ObservableObject {
    @Published public var assets: [PhotosBrowserLibraryEntity]
    @Published public var currentIndex: Int = 0
    
    var currentAsset: PhotosBrowserLibraryEntity? {
        assets[safe: currentIndex]
    }
    
    // MARK: Lifecycle
    
    public init(assets: [PhotosBrowserLibraryEntity], currentIndex: Int) {
        self.assets = assets
        self.currentIndex = currentIndex
    }
}
