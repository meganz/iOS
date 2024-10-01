import Foundation
import MEGADomain

public final class MediaLibrary: ObservableObject {
    @Published var assets: [PhotosBrowserLibraryEntity]
    var currentIndex: Int = 0
    
    lazy var currentAsset: PhotosBrowserLibraryEntity = {
        assets[currentIndex]
    }()
    
    // MARK: Lifecycle
    
    public init(assets: [PhotosBrowserLibraryEntity], currentIndex: Int) {
        self.assets = assets
        self.currentIndex = currentIndex
    }
}
