import Combine
import Foundation
import MEGADomain

public class PhotosBrowserCollectionViewModel: ObservableObject {
    private var subscriptions = Set<AnyCancellable>()
    @Published private(set) var mediaAssets: [PhotosBrowserLibraryEntity]
    
    // MARK: Lifecycle
    
    init(library: MediaLibrary) {
        mediaAssets = library.assets
        
        subscribeAssetsChange(with: library)
    }
    
    // MARK: Private
    
    private func subscribeAssetsChange(with library: MediaLibrary) {
        library.$assets.sink { [weak self] newAssets in
            self?.mediaAssets = newAssets
        }
        .store(in: &subscriptions)
    }
}
